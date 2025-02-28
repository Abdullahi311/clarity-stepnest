(define-fungible-token step-token)

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-insufficient-balance (err u101))
(define-constant token-name "StepToken")
(define-constant token-symbol "STEP")

(define-public (mint (amount uint) (recipient principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (ok (ft-mint? step-token amount recipient))))

(define-public (transfer (amount uint) (sender principal) (recipient principal))
  (begin
    (asserts! (is-eq tx-sender sender) (err u102))
    (ft-transfer? step-token amount sender recipient)))

(define-read-only (get-balance (owner principal))
  (ok (ft-get-balance step-token owner)))

(define-read-only (get-token-info)
  (ok {
    name: token-name,
    symbol: token-symbol,
    decimals: u6
  }))
