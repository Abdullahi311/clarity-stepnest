;; Route structure
(define-map routes
  { route-id: uint }
  {
    creator: principal,
    name: (string-utf8 100),
    description: (string-utf8 500),
    difficulty: uint,
    length: uint,
    rating: uint,
    total-reviews: uint
  })

;; User completion tracking
(define-map user-completions
  { user: principal, route-id: uint }
  { completed: bool, timestamp: uint })

;; User ratings tracking
(define-map user-ratings
  { user: principal, route-id: uint }
  { rating: uint })

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-invalid-route (err u101))
(define-constant err-invalid-params (err u102))
(define-constant err-already-completed (err u103))
(define-constant err-invalid-rating (err u104))
(define-constant err-not-completed (err u105))
(define-data-var next-route-id uint u1)

;; Create new route
(define-public (create-route (name (string-utf8 100)) 
                           (description (string-utf8 500))
                           (difficulty uint)
                           (length uint))
  (begin
    (asserts! (and (> difficulty u0) (<= difficulty u5)) err-invalid-params)
    (asserts! (> length u0) err-invalid-params)
    (let ((route-id (var-get next-route-id)))
      (map-set routes
        { route-id: route-id }
        {
          creator: tx-sender,
          name: name,
          description: description,
          difficulty: difficulty,
          length: length,
          rating: u0,
          total-reviews: u0
        })
      (var-set next-route-id (+ route-id u1))
      (ok route-id))))

;; Rate a completed route
(define-public (rate-route (route-id uint) (rating uint))
  (let ((route (map-get? routes { route-id: route-id }))
        (completion (map-get? user-completions { user: tx-sender, route-id: route-id })))
    (asserts! (is-some route) err-invalid-route)
    (asserts! (is-some completion) err-not-completed)
    (asserts! (and (>= rating u1) (<= rating u5)) err-invalid-rating)
    (let ((current-route (unwrap-panic route)))
      (map-set user-ratings
        { user: tx-sender, route-id: route-id }
        { rating: rating })
      (map-set routes
        { route-id: route-id }
        (merge current-route
          {
            rating: (+ (get rating current-route) rating),
            total-reviews: (+ (get total-reviews current-route) u1)
          }))
      (ok true))))

;; Mark route as completed and reward user
(define-public (complete-route (route-id uint))
  (let ((route (map-get? routes { route-id: route-id })))
    (asserts! (is-some route) err-invalid-route)
    (asserts! (is-none (map-get? user-completions 
      { user: tx-sender, route-id: route-id })) 
      err-already-completed)
    (begin
      (map-set user-completions
        { user: tx-sender, route-id: route-id }
        { completed: true, timestamp: block-height })
      ;; Enhanced reward calculation based on difficulty and length
      (let ((reward-amount (* (get difficulty (unwrap-panic route))
                            (/ (get length (unwrap-panic route)) u1000))))
        (try! (contract-call? .step-token mint reward-amount tx-sender)))
      (ok true))))
