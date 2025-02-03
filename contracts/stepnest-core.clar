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
(define-data-var next-route-id uint u1)

;; Create new route
(define-public (create-route (name (string-utf8 100)) 
                           (description (string-utf8 500))
                           (difficulty uint)
                           (length uint))
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
    (ok route-id)))

;; Mark route as completed
(define-public (complete-route (route-id uint))
  (begin
    (map-set user-completions
      { user: tx-sender, route-id: route-id }
      { completed: true, timestamp: block-height })
    (ok true)))
