;; SPV9K21TBFAK4KNRJXF5DFP8N7W46G4V9RCJDC22.ai1-faktory-dex
;; 99af7ff63e5e4bd7542e55d88bacc25a7a6f79004f9937ea0bab3ca4c2438061
  ;; aibtc.dev DAO faktory.fun DEX @version 1.0

  ;; (impl-trait 'SP29CK9990DQGE9RGTT1VEQTTYH8KY4E3JE5XP4EC.aibtcdev-dao-traits-v1.token-dex)
  ;; (impl-trait 'SP3XXMS38VTAWTVPE5682XSBFXPTH7XCPEBTX8AN2.faktory-dex-trait-v1.dex-trait)
  (use-trait faktory-token .faktory-trait-v1.sip-010-trait) ;;SP3XXMS38VTAWTVPE5682XSBFXPTH7XCPEBTX8AN2
  
  (define-constant ERR-MARKET-CLOSED (err u1001))
  (define-constant ERR-STX-NON-POSITIVE (err u1002))
  (define-constant ERR-STX-BALANCE-TOO-LOW (err u1003))
  (define-constant ERR-FT-NON-POSITIVE (err u1004))
  (define-constant ERR-TOKEN-NOT-AUTH (err u401))
  (define-constant ERR-UNAUTHORIZED-CALLER (err u402))
  
  (define-constant FEE-RECEIVER 'ST3S2565C4DP2MGR3CMANMGYDCDA314Q25AQGR26R) ;; 'SMHAVPYZ8BVD0BHBBQGY5AQVVGNQY4TNHAKGPYP)
  (define-constant G-RECEIVER 'ST3CZY55VJE5P5DJAP5E58X123BZKMYDCNEZMRTV2) ;;'SM3NY5HXXRNCHS1B65R78CYAC1TQ6DEMN3C0DN74S)

  (define-constant CANT-BE-EVIL 'ST3S5KBK62Z4K9XV2HFADJDA5QSRQWGQWTBP0APDY) ;;'SP000000000000000000002Q6VF78)
  (define-constant DEV tx-sender)
  (define-constant DEX-TOKEN .ai1-faktory) ;; SPV9K21TBFAK4KNRJXF5DFP8N7W46G4V9RCJDC22
  (define-constant AUTHORIZED-CONTRACT .ai1-faktory) ;; 'SPV9K21TBFAK4KNRJXF5DFP8N7W46G4V9RCJDC22.buy-with-velar-faktory)
  
  ;; token constants
  (define-constant TARGET_STX u2000000000)
  (define-constant FAK_STX u400000000)
  (define-constant GRAD-FEE u40000000)
  
  ;; data vars
  (define-data-var open bool false)
  (define-data-var fak-ustx uint u0)
  (define-data-var ft-balance uint u0)
  (define-data-var stx-balance uint u0)
  (define-data-var burn-rate uint u25)
  
  ;; Helper function to check if caller is authorized
  (define-private (is-valid-caller)
    (or 
      (is-eq contract-caller tx-sender)
      (is-eq contract-caller AUTHORIZED-CONTRACT)
    ))
  
  (define-public (buy (ft <faktory-token>) (ustx uint))
    (begin
      (asserts! (is-eq DEX-TOKEN (contract-of ft)) ERR-TOKEN-NOT-AUTH)
      (asserts! (is-valid-caller) ERR-UNAUTHORIZED-CALLER)
      (asserts! (var-get open) ERR-MARKET-CLOSED)
      (asserts! (> ustx u0) ERR-STX-NON-POSITIVE)
      (let ((total-stx (var-get stx-balance))
            (total-stk (+ total-stx (var-get fak-ustx)))
            (total-ft (var-get ft-balance))
            (k (* total-ft total-stk))
            (fee (/ (* ustx u2) u100))
            (stx-in (- ustx fee))
            (new-stk (+ total-stk stx-in))
            (new-ft (/ k new-stk))
            (tokens-out (- total-ft new-ft))
            (new-stx (+ total-stx stx-in))
            (ft-receiver tx-sender))
        (try! (stx-transfer? fee tx-sender FEE-RECEIVER))
        (try! (stx-transfer? stx-in tx-sender (as-contract tx-sender)))
        (try! (as-contract (contract-call? ft transfer tokens-out tx-sender ft-receiver none)))
        (if (>= new-stx TARGET_STX)
          (begin
            (let ((burn-amount (/ (* new-ft (var-get burn-rate)) u100))
                  (amm-amount (- new-ft burn-amount))
                  (amm-ustx (- new-stx GRAD-FEE))
                  (xyk-pool-uri (default-to u"https://bitflow.finance" (try! (contract-call? ft get-token-uri))))
                  (xyk-burn-amount (- (sqrti (* amm-ustx amm-amount)) u1)))
              (try! (as-contract (contract-call? ft transfer burn-amount tx-sender CANT-BE-EVIL none)))
            ;;   (try! (as-contract 
            ;;          (contract-call? 
            ;;            'SM1793C4R5PZ4NS4VQ4WMP7SKKYVH8JZEWSZ9HCCR.xyk-core-v-1-2 
            ;;                create-pool 
            ;;                'SPV9K21TBFAK4KNRJXF5DFP8N7W46G4V9RCJDC22.xyk-pool-stx-ai1-v1-1
            ;;                'SM1793C4R5PZ4NS4VQ4WMP7SKKYVH8JZEWSZ9HCCR.token-stx-v-1-2 
            ;;                ft
            ;;                amm-ustx 
            ;;                amm-amount 
            ;;                xyk-burn-amount 
            ;;                u10 u40 u10 u40 
            ;;                'SP31C60QVZKZ9CMMZX73TQ3F3ZZNS89YX2DCCFT8P xyk-pool-uri true)))
              (try! (as-contract (stx-transfer? GRAD-FEE tx-sender G-RECEIVER)))
              (var-set open false)
              (var-set stx-balance u0)
              (var-set ft-balance u0)
              (print {type: "buy", ft: (contract-of ft), tokens-out: tokens-out, ustx: ustx, burn-amount: burn-amount, amm-amount: amm-amount,
                      amm-ustx: amm-ustx,
                      stx-balance: u0, ft-balance: u0,
                      fee: fee, grad-fee: GRAD-FEE, maker: tx-sender,
                      open: false})
              (ok true)))
          (begin
            (var-set stx-balance new-stx)
            (var-set ft-balance new-ft)
            (print {type: "buy", ft: (contract-of ft), tokens-out: tokens-out, ustx: ustx, maker: tx-sender,
                    stx-balance: new-stx, ft-balance: new-ft,
                    fee: fee,
                    open: true})
            (ok true))))))
  
  (define-read-only (get-in (ustx uint))
    (let ((total-stx (var-get stx-balance))
          (total-stk (+ total-stx (var-get fak-ustx)))
          (total-ft (var-get ft-balance))
          (k (* total-ft total-stk))
          (fee (/ (* ustx u2) u100))
          (stx-in (- ustx fee))
          (new-stk (+ total-stk stx-in))
          (new-ft (/ k new-stk))
          (tokens-out (- total-ft new-ft))
          (raw-to-grad (- TARGET_STX total-stx))
          (stx-to-grad (/ (* raw-to-grad u103) u100)))
      (ok {stx-in: stx-in,
           fee: fee,
           tokens-out: tokens-out,
           ft-balance: total-ft,
           new-ft: new-ft,
           total-stx: total-stx,
           new-stx: (+ total-stx stx-in),
           stx-to-grad: stx-to-grad})))
  
  (define-public (sell (ft <faktory-token>) (amount uint))
    (begin
      (asserts! (is-eq DEX-TOKEN (contract-of ft)) ERR-TOKEN-NOT-AUTH)
      (asserts! (is-valid-caller) ERR-UNAUTHORIZED-CALLER)
      (asserts! (var-get open) ERR-MARKET-CLOSED)
      (asserts! (> amount u0) ERR-FT-NON-POSITIVE)
      (let ((total-stx (var-get stx-balance))
            (total-stk (+ total-stx (var-get fak-ustx)))
            (total-ft (var-get ft-balance))
            (k (* total-ft total-stk))
            (new-ft (+ total-ft amount))
            (new-stk (/ k new-ft))
            (stx-out (- (- total-stk new-stk) u1))
            (fee (/ (* stx-out u2) u100))
            (stx-to-receiver (- stx-out fee))
            (new-stx (- total-stx stx-out))
            (stx-receiver tx-sender))
        (asserts! (>= total-stx stx-out) ERR-STX-BALANCE-TOO-LOW)
        (try! (contract-call? ft transfer amount tx-sender (as-contract tx-sender) none))
        (try! (as-contract (stx-transfer? stx-to-receiver tx-sender stx-receiver)))
        (try! (as-contract (stx-transfer? fee tx-sender FEE-RECEIVER)))
        (var-set stx-balance new-stx)
        (var-set ft-balance new-ft)
        (print {type: "sell", ft: (contract-of ft), amount: amount, stx-to-receiver: stx-to-receiver, maker: tx-sender,
                stx-balance: new-stx, ft-balance: new-ft,
                fee: fee,
                open: true})
        (ok true))))
  
  (define-read-only (get-out (amount uint))
    (let ((total-stx (var-get stx-balance))
          (total-stk (+ total-stx (var-get fak-ustx)))
          (total-ft (var-get ft-balance))
          (k (* total-ft total-stk))
          (new-ft (+ total-ft amount))
          (new-stk (/ k new-ft))
          (stx-out (- (- total-stk new-stk) u1))
          (fee (/ (* stx-out u2) u100))
          (stx-to-receiver (- stx-out fee)))
      (ok {amount-in: amount,
           stx-out: stx-out,
           fee: fee,
           stx-to-receiver: stx-to-receiver,
           total-stx: total-stx,
           new-stx: (- total-stx stx-out),
           ft-balance: total-ft,
           new-ft: new-ft})))
  
  (define-read-only (get-open)
    (ok (var-get open)))
  
  ;; boot dex
    (begin
      (var-set fak-ustx FAK_STX)
      (var-set ft-balance u13800000000000)
      (var-set stx-balance u0)
      (var-set open true)
      (try! (stx-transfer? u500000 tx-sender 'ST3S2565C4DP2MGR3CMANMGYDCDA314Q25AQGR26R)) ;;'SMH8FRN30ERW1SX26NJTJCKTDR3H27NRJ6W75WQE))
        (print { 
            type: "faktory-dex-trait-v1", 
            dexContract: (as-contract tx-sender),
            ;; ammReceiver: 'SM1793C4R5PZ4NS4VQ4WMP7SKKYVH8JZEWSZ9HCCR.xyk-core-v-1-2,
            ;; poolName: 'SPV9K21TBFAK4KNRJXF5DFP8N7W46G4V9RCJDC22.xyk-pool-stx-ai1-v1-1
       })
      (ok true))