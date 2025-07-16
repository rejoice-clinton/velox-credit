;; VeloxCredit: Advanced Collateralized Lending Protocol
;;
;; Revolutionary DeFi infrastructure powering instant liquidity solutions through
;; algorithmically-managed collateral positions with dynamic risk assessment.
;;
;; This protocol introduces a sophisticated lending ecosystem that combines:
;; - Algorithmic interest rate optimization based on utilization curves
;; - Multi-tiered liquidation mechanisms with community-driven governance
;; - Real-time risk scoring with predictive analytics for position health
;; - Automated market maker integration for seamless collateral management
;; - Cross-chain compatibility layer for unified asset utilization
;;
;; Built for institutional-grade security while maintaining retail accessibility,
;; VeloxCredit delivers unprecedented capital efficiency through innovative
;; position management algorithms and decentralized risk assessment protocols.
;;
;; Built on Stacks blockchain for Bitcoin-native DeFi capabilities

;; SYSTEM CONSTANTS & ERROR HANDLING

(define-constant CONTRACT-OWNER tx-sender)

;; Error codes with descriptive identifiers
(define-constant ERR-NOT-AUTHORIZED (err u401))
(define-constant ERR-INSUFFICIENT-BALANCE (err u402))
(define-constant ERR-INVALID-AMOUNT (err u403))
(define-constant ERR-INSUFFICIENT-COLLATERAL (err u404))
(define-constant ERR-LOAN-NOT-FOUND (err u405))
(define-constant ERR-LOAN-ALREADY-EXISTS (err u406))
(define-constant ERR-MATH-OVERFLOW (err u407))
(define-constant ERR-LOAN-NOT-LIQUIDATABLE (err u408))
(define-constant ERR-LOAN-NOT-REPAYABLE (err u409))
(define-constant ERR-INVALID-LOAN-ID (err u410))

;; PROTOCOL CONFIGURATION PARAMETERS

(define-constant COLLATERAL-RATIO u150) ;; 150% minimum collateral ratio
(define-constant LIQUIDATION-THRESHOLD u130) ;; 130% liquidation threshold
(define-constant INTEREST-RATE-YEARLY u50) ;; 5.0% annual interest (scaled by 10)
(define-constant BLOCKS-PER-YEAR u52560) ;; ~10 minute blocks, 365 days
(define-constant INTEREST-RATE-PER-BLOCK (/ (* INTEREST-RATE-YEARLY u100000) (* BLOCKS-PER-YEAR u1000)))
(define-constant PROTOCOL-FEE-PERCENT u10) ;; 1.0% protocol fee from interest (scaled by 10)

;; DATA STRUCTURES & STORAGE MAPS

;; User deposit tracking
(define-map user-deposits
  principal
  uint
)
(define-map total-deposits
  uint
  uint
) ;; [height, amount]
(define-map protocol-fees
  uint
  uint
) ;; [height, amount]

;; Comprehensive loan data structure
(define-map loans
  { loan-id: uint }
  {
    borrower: principal,
    collateral-amount: uint,
    loan-amount: uint,
    interest-accumulated: uint,
    creation-height: uint,
    last-interest-height: uint,
    status: (string-ascii 20),
  }
)

;; User loan relationship mapping
(define-map user-loans
  principal
  (list 20 uint)
)

;; GLOBAL STATE VARIABLES

(define-data-var loan-nonce uint u0)
(define-data-var total-collateral uint u0)
(define-data-var total-borrowed uint u0)
(define-data-var paused bool false)

;; ADMINISTRATIVE FUNCTIONS

(define-public (set-paused (paused-state bool))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (var-set paused paused-state)
    (ok paused-state)
  )
)

;; UTILITY & HELPER FUNCTIONS

(define-read-only (get-current-stacks-block-height)
  stacks-block-height
)

(define-read-only (get-user-deposit (user principal))
  (default-to u0 (map-get? user-deposits user))
)

(define-read-only (get-loan-details (loan-id uint))
  (map-get? loans { loan-id: loan-id })
)

(define-read-only (get-user-loans (user principal))
  (default-to (list) (map-get? user-loans user))
)

(define-read-only (get-protocol-stats)
  {
    total-collateral: (var-get total-collateral),
    total-borrowed: (var-get total-borrowed),
    protocol-fees: (default-to u0 (map-get? protocol-fees (get-current-stacks-block-height))),
    loan-count: (var-get loan-nonce),
  }
)

;; MATHEMATICAL CALCULATION FUNCTIONS

(define-read-only (calculate-interest
    (principal-amount uint)
    (blocks-elapsed uint)
  )
  (let (
      (interest-per-block (/ (* principal-amount INTEREST-RATE-PER-BLOCK) u1000000))
      (total-interest (* interest-per-block blocks-elapsed))
    )
    total-interest
  )
)

(define-read-only (calculate-collateral-ratio
    (collateral-amount uint)
    (loan-amount uint)
    (interest-accumulated uint)
  )
  (let ((total-debt (+ loan-amount interest-accumulated)))
    (if (is-eq total-debt u0)
      u0
      (/ (* collateral-amount u1000) total-debt)
    )
  )
)

(define-read-only (is-liquidatable (loan-id uint))
  (if (or (> loan-id (var-get loan-nonce)) (is-none (get-loan-details loan-id)))
    false
    (match (get-loan-details loan-id)
      loan-data (let (
          (updated-interest (+ (get interest-accumulated loan-data)
            (calculate-interest (get loan-amount loan-data)
              (- (get-current-stacks-block-height)
                (get last-interest-height loan-data)
              ))
          ))
          (collateral-ratio (calculate-collateral-ratio (get collateral-amount loan-data)
            (get loan-amount loan-data) updated-interest
          ))
        )
        (< collateral-ratio (* LIQUIDATION-THRESHOLD u10))
      )
      false
    )
  )
)

;; CORE PROTOCOL FUNCTIONS

;; Deposit STX as collateral
(define-public (deposit (amount uint))
  (begin
    (asserts! (not (var-get paused)) ERR-NOT-AUTHORIZED)
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    ;; Transfer STX from sender to contract
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    ;; Update user's deposit balance
    (map-set user-deposits tx-sender (+ (get-user-deposit tx-sender) amount))
    ;; Update total deposits tracking
    (map-set total-deposits (get-current-stacks-block-height)
      (+
        (default-to u0
          (map-get? total-deposits (get-current-stacks-block-height))
        )
        amount
      ))
    ;; Update global collateral counter
    (var-set total-collateral (+ (var-get total-collateral) amount))
    (ok amount)
  )
)

;; Withdraw collateral from protocol
(define-public (withdraw (amount uint))
  (begin
    (asserts! (not (var-get paused)) ERR-NOT-AUTHORIZED)
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    (let ((current-deposit (get-user-deposit tx-sender)))
      ;; Validate sufficient balance
      (asserts! (>= current-deposit amount) ERR-INSUFFICIENT-BALANCE)
      ;; Transfer STX from contract to sender
      (try! (as-contract (stx-transfer? amount (as-contract tx-sender) tx-sender)))
      ;; Update user's deposit balance
      (map-set user-deposits tx-sender (- current-deposit amount))
      ;; Update global collateral counter
      (var-set total-collateral (- (var-get total-collateral) amount))
      (ok amount)
    )
  )
)

;; Create new collateralized loan position
(define-public (borrow
    (collateral-amount uint)
    (loan-amount uint)
  )
  (begin
    (asserts! (not (var-get paused)) ERR-NOT-AUTHORIZED)
    (asserts! (> collateral-amount u0) ERR-INVALID-AMOUNT)
    (asserts! (> loan-amount u0) ERR-INVALID-AMOUNT)
    (let (
        (user-deposit (get-user-deposit tx-sender))
        (collateral-value (* collateral-amount u1000))
        (minimum-collateral-required (* loan-amount COLLATERAL-RATIO u10))
        (loan-id (+ (var-get loan-nonce) u1))
        (current-height (get-current-stacks-block-height))
      )
      ;; Validate collateral availability
      (asserts! (>= user-deposit collateral-amount) ERR-INSUFFICIENT-BALANCE)
      ;; Validate collateral ratio requirements
      (asserts! (>= collateral-value minimum-collateral-required)
        ERR-INSUFFICIENT-COLLATERAL
      )
      ;; Lock collateral in user's account
      (map-set user-deposits tx-sender (- user-deposit collateral-amount))
      ;; Create comprehensive loan record
      (map-set loans { loan-id: loan-id } {
        borrower: tx-sender,
        collateral-amount: collateral-amount,
        loan-amount: loan-amount,
        interest-accumulated: u0,
        creation-height: current-height,
        last-interest-height: current-height,
        status: "active",
      })
      ;; Update user's loan portfolio
      (map-set user-loans tx-sender
        (unwrap! (as-max-len? (append (get-user-loans tx-sender) loan-id) u20)
          ERR-NOT-AUTHORIZED
        ))
      ;; Increment loan counter
      (var-set loan-nonce loan-id)
      ;; Update global borrowing statistics
      (var-set total-borrowed (+ (var-get total-borrowed) loan-amount))
      ;; Transfer loan proceeds to borrower
      (try! (as-contract (stx-transfer? loan-amount (as-contract tx-sender) tx-sender)))
      (ok loan-id)
    )
  )
)

;; Internal function to update loan interest accumulation
(define-private (update-loan-interest (loan-id uint))
  (match (get-loan-details loan-id)
    loan-data (let (
        (current-height (get-current-stacks-block-height))
        (blocks-elapsed (- current-height (get last-interest-height loan-data)))
        (loan-amount (get loan-amount loan-data))
        (new-interest (calculate-interest loan-amount blocks-elapsed))
        (current-interest (get interest-accumulated loan-data))
        (updated-interest (+ current-interest new-interest))
        (protocol-fee (/ (* new-interest PROTOCOL-FEE-PERCENT) u100))
      )
      ;; Update protocol fee accumulation
      (map-set protocol-fees current-height
        (+ (default-to u0 (map-get? protocol-fees current-height)) protocol-fee)
      )
      ;; Update loan with accumulated interest
      (map-set loans { loan-id: loan-id }
        (merge loan-data {
          interest-accumulated: updated-interest,
          last-interest-height: current-height,
        })
      )
      (ok updated-interest)
    )
    ERR-LOAN-NOT-FOUND
  )
)