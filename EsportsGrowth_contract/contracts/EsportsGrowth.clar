
;; title: EsportsGrowth
;; version: 1.0.0
;; summary: Synthetic assets smart contract for tracking competitive gaming and esports industry revenue
;; description: This contract manages synthetic assets that track the performance and revenue of the esports industry,
;;              allowing users to mint, trade, and redeem synthetic tokens representing esports market performance.

;; traits
;; Note: SIP-010 trait can be implemented later if needed

;; token definitions
(define-fungible-token esports-synthetic-token)

;; constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-OWNER-ONLY (err u100))
(define-constant ERR-NOT-FOUND (err u101))
(define-constant ERR-INSUFFICIENT-BALANCE (err u102))
(define-constant ERR-INVALID-AMOUNT (err u103))
(define-constant ERR-ORACLE-NOT-AUTHORIZED (err u104))
(define-constant ERR-PRICE-TOO-OLD (err u105))
(define-constant ERR-INVALID-RATIO (err u106))

;; Minimum collateral ratio (150%)
(define-constant MIN-COLLATERAL-RATIO u150)
(define-constant PRECISION u1000000) ;; 6 decimal precision
(define-constant MAX-PRICE-AGE u144) ;; Maximum price age in blocks (approximately 24 hours)

;; data vars
(define-data-var total-supply uint u0)
(define-data-var oracle-address principal CONTRACT-OWNER)
(define-data-var current-esports-revenue uint u0)
(define-data-var last-price-update uint u0)
(define-data-var synthetic-price uint PRECISION) ;; Price starts at 1.0
(define-data-var total-collateral uint u0)

;; data maps
(define-map balances principal uint)
(define-map collateral-positions principal uint)
(define-map synthetic-positions principal uint)
(define-map authorized-oracles principal bool)

;; Revenue data for different esports categories
(define-map esports-categories
  {category: (string-ascii 50)}
  {
    revenue: uint,
    last-updated: uint,
    weight: uint ;; Weight in the overall calculation (out of 100)
  }
)

;; public functions

;; Initialize the contract with basic esports categories
(define-public (initialize)
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-OWNER-ONLY)
    (map-set esports-categories {category: "competitive-gaming"} {revenue: u0, last-updated: block-height, weight: u40})
    (map-set esports-categories {category: "streaming-platforms"} {revenue: u0, last-updated: block-height, weight: u30})
    (map-set esports-categories {category: "sponsorships"} {revenue: u0, last-updated: block-height, weight: u20})
    (map-set esports-categories {category: "merchandise"} {revenue: u0, last-updated: block-height, weight: u10})
    (map-set authorized-oracles CONTRACT-OWNER true)
    (ok true)
  )
)

;; Mint synthetic tokens with STX collateral
(define-public (mint-synthetic (amount uint) (stx-collateral uint))
  (let (
    (current-price (var-get synthetic-price))
    (required-collateral (/ (* amount current-price MIN-COLLATERAL-RATIO) u100))
    (sender tx-sender)
  )
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    (asserts! (>= stx-collateral required-collateral) ERR-INSUFFICIENT-BALANCE)

    ;; Transfer STX as collateral
    (try! (stx-transfer? stx-collateral sender (as-contract tx-sender)))

    ;; Update positions
    (map-set collateral-positions sender
      (+ (default-to u0 (map-get? collateral-positions sender)) stx-collateral))
    (map-set synthetic-positions sender
      (+ (default-to u0 (map-get? synthetic-positions sender)) amount))

    ;; Mint tokens
    (try! (ft-mint? esports-synthetic-token amount sender))

    ;; Update totals
    (var-set total-supply (+ (var-get total-supply) amount))
    (var-set total-collateral (+ (var-get total-collateral) stx-collateral))

    (ok amount)
  )
)

;; Burn synthetic tokens and redeem collateral
(define-public (burn-synthetic (amount uint))
  (let (
    (sender tx-sender)
    (current-balance (default-to u0 (map-get? synthetic-positions sender)))
    (current-collateral (default-to u0 (map-get? collateral-positions sender)))
    (current-price (var-get synthetic-price))
    (collateral-to-return (/ (* amount current-collateral) current-balance))
  )
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    (asserts! (>= current-balance amount) ERR-INSUFFICIENT-BALANCE)

    ;; Burn tokens
    (try! (ft-burn? esports-synthetic-token amount sender))

    ;; Update positions
    (map-set synthetic-positions sender (- current-balance amount))
    (map-set collateral-positions sender (- current-collateral collateral-to-return))

    ;; Return STX collateral
    (try! (as-contract (stx-transfer? collateral-to-return tx-sender sender)))

    ;; Update totals
    (var-set total-supply (- (var-get total-supply) amount))
    (var-set total-collateral (- (var-get total-collateral) collateral-to-return))

    (ok collateral-to-return)
  )
)

;; Update esports revenue data (oracle function)
(define-public (update-revenue (category (string-ascii 50)) (new-revenue uint))
  (let (
    (sender tx-sender)
    (is-authorized (default-to false (map-get? authorized-oracles sender)))
  )
    (asserts! is-authorized ERR-ORACLE-NOT-AUTHORIZED)
    (asserts! (> new-revenue u0) ERR-INVALID-AMOUNT)

    (match (map-get? esports-categories {category: category})
      existing-data
        (begin
          (map-set esports-categories {category: category}
            (merge existing-data {revenue: new-revenue, last-updated: block-height}))
          (try! (calculate-synthetic-price))
          (ok true)
        )
      ERR-NOT-FOUND
    )
  )
)

;; Calculate and update synthetic price based on esports revenue
(define-public (calculate-synthetic-price)
  (let (
    (competitive-data (unwrap! (map-get? esports-categories {category: "competitive-gaming"}) ERR-NOT-FOUND))
    (streaming-data (unwrap! (map-get? esports-categories {category: "streaming-platforms"}) ERR-NOT-FOUND))
    (sponsorship-data (unwrap! (map-get? esports-categories {category: "sponsorships"}) ERR-NOT-FOUND))
    (merchandise-data (unwrap! (map-get? esports-categories {category: "merchandise"}) ERR-NOT-FOUND))

    (weighted-revenue (+
      (/ (* (get revenue competitive-data) (get weight competitive-data)) u100)
      (/ (* (get revenue streaming-data) (get weight streaming-data)) u100)
      (/ (* (get revenue sponsorship-data) (get weight sponsorship-data)) u100)
      (/ (* (get revenue merchandise-data) (get weight merchandise-data)) u100)
    ))

    ;; Simple price calculation: base price + (weighted-revenue / scaling-factor)
    (new-price (+ PRECISION (/ weighted-revenue u1000000)))
  )
    (var-set current-esports-revenue weighted-revenue)
    (var-set synthetic-price new-price)
    (var-set last-price-update block-height)
    (ok new-price)
  )
)

;; Add authorized oracle
(define-public (add-oracle (oracle principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-OWNER-ONLY)
    (map-set authorized-oracles oracle true)
    (ok true)
  )
)

;; Remove authorized oracle
(define-public (remove-oracle (oracle principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-OWNER-ONLY)
    (map-delete authorized-oracles oracle)
    (ok true)
  )
)

;; Transfer synthetic tokens
(define-public (transfer (amount uint) (sender principal) (recipient principal) (memo (optional (buff 34))))
  (begin
    (asserts! (is-eq tx-sender sender) ERR-OWNER-ONLY)
    (ft-transfer? esports-synthetic-token amount sender recipient)
  )
)

;; read only functions

;; Get token balance
(define-read-only (get-balance (account principal))
  (default-to u0 (map-get? balances account))
)

;; Get total supply
(define-read-only (get-total-supply)
  (var-get total-supply)
)

;; Get current synthetic price
(define-read-only (get-synthetic-price)
  (var-get synthetic-price)
)

;; Get esports revenue data
(define-read-only (get-category-revenue (category (string-ascii 50)))
  (map-get? esports-categories {category: category})
)

;; Get total esports revenue
(define-read-only (get-total-esports-revenue)
  (var-get current-esports-revenue)
)

;; Get collateral position
(define-read-only (get-collateral-position (account principal))
  (default-to u0 (map-get? collateral-positions account))
)

;; Get synthetic position
(define-read-only (get-synthetic-position (account principal))
  (default-to u0 (map-get? synthetic-positions account))
)

;; Check if oracle is authorized
(define-read-only (is-authorized-oracle (oracle principal))
  (default-to false (map-get? authorized-oracles oracle))
)

;; Get collateral ratio for a position
(define-read-only (get-collateral-ratio (account principal))
  (let (
    (collateral (default-to u0 (map-get? collateral-positions account)))
    (synthetic (default-to u0 (map-get? synthetic-positions account)))
    (current-price (var-get synthetic-price))
  )
    (if (is-eq synthetic u0)
      u0
      (/ (* collateral u100) (* synthetic current-price))
    )
  )
)

;; Check if price data is stale
(define-read-only (is-price-stale)
  (> (- block-height (var-get last-price-update)) MAX-PRICE-AGE)
)

;; Get contract metadata
(define-read-only (get-contract-info)
  {
    total-supply: (var-get total-supply),
    total-collateral: (var-get total-collateral),
    synthetic-price: (var-get synthetic-price),
    current-revenue: (var-get current-esports-revenue),
    last-update: (var-get last-price-update),
    contract-owner: CONTRACT-OWNER
  }
)

;; private functions

;; Liquidation check (internal function for future use)
(define-private (check-liquidation (account principal))
  (let (
    (ratio (get-collateral-ratio account))
  )
    (< ratio MIN-COLLATERAL-RATIO)
  )
)
