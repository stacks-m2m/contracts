(impl-trait .aibtcdev-dao-traits-v1.extension)
(impl-trait .aibtcdev-dao-traits-v1.action)

(define-constant ERR_UNAUTHORIZED (err u10001))
(define-constant ERR_INVALID_PARAMS (err u10002))
(define-constant ERR_PARAMS_OUT_OF_RANGE (err u10003))

(define-public (callback (sender principal) (memo (buff 34))) (ok true))

(define-public (run (parameters (buff 2048)))
  (let
    (
      (amount (unwrap! (from-consensus-buff? uint parameters) ERR_INVALID_PARAMS))
    )
    (try! (is-dao-or-extension))
    ;; verify within limits for low quorum
    ;; more than 0, less than 100 STX (100_000_000)
    (asserts! (and (> amount u0) (< amount u100000000)) ERR_INVALID_PARAMS)
    (contract-call? .aibtc-bank-account set-withdrawal-amount amount)
  )
)

(define-private (is-dao-or-extension)
  (ok (asserts! (or (is-eq tx-sender .aibtcdev-base-dao)
    (contract-call? .aibtcdev-base-dao is-extension contract-caller)) ERR_UNAUTHORIZED
  ))
)