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

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-invalid-route (err u101))
(define-constant err-invalid-params (err u102))
(define-constant err-already-completed (err u103))
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
      ;; Reward user with tokens based on route difficulty
      (try! (contract-call? .step-token mint 
        (* u10 (get difficulty (unwrap-panic route))) 
        tx-sender))
      (ok true))))
