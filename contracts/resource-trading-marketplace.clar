
;; title: resource-trading-marketplace
;; version: 1.0.0
;; summary: Renewable resource trading marketplace with automated price discovery
;; description: Facilitates trading of water credits, forest certificates, and biodiversity tokens
;; with automated pricing, compliance retirement, and project funding distribution

;; traits
;;

;; token definitions
;;

;; constants
;;
(define-constant ERR_UNAUTHORIZED (err u200))
(define-constant ERR_LISTING_NOT_FOUND (err u201))
(define-constant ERR_INSUFFICIENT_BALANCE (err u202))
(define-constant ERR_INVALID_AMOUNT (err u203))
(define-constant ERR_INVALID_PRICE (err u204))
(define-constant ERR_LISTING_NOT_ACTIVE (err u205))
(define-constant ERR_BUYER_IS_SELLER (err u206))
(define-constant ERR_INSUFFICIENT_PAYMENT (err u207))
(define-constant ERR_INVALID_RESOURCE_TYPE (err u208))
(define-constant ERR_ALREADY_RETIRED (err u209))
(define-constant ERR_ORDER_NOT_FOUND (err u210))

(define-constant CONTRACT_OWNER tx-sender)
(define-constant MARKETPLACE_FEE_PERCENT u3) ;; 3% marketplace fee
(define-constant FUNDING_DISTRIBUTION_PERCENT u60) ;; 60% goes to projects
(define-constant BASE_PRICE u1000) ;; Base price in microSTX
(define-constant PRICE_MULTIPLIER u100)

;; Resource types
(define-constant RESOURCE_WATER u1)
(define-constant RESOURCE_FOREST u2)
(define-constant RESOURCE_BIODIVERSITY u3)

;; Listing status
(define-constant STATUS_ACTIVE u1)
(define-constant STATUS_SOLD u2)
(define-constant STATUS_CANCELLED u3)

;; data vars
;;
(define-data-var next-listing-id uint u1)
(define-data-var next-order-id uint u1)
(define-data-var total-volume-traded uint u0)
(define-data-var total-marketplace-fees uint u0)
(define-data-var total-project-funding uint u0)

;; Resource-specific trading volumes
(define-data-var water-credits-traded uint u0)
(define-data-var forest-credits-traded uint u0)
(define-data-var biodiversity-tokens-traded uint u0)

;; data maps
;;
;; Resource credit listings
(define-map credit-listings
  { listing-id: uint }
  {
    seller: principal,
    resource-type: uint, ;; 1=water, 2=forest, 3=biodiversity
    amount: uint,
    price-per-unit: uint,
    total-price: uint,
    project-id: (optional uint),
    status: uint,
    created-at: uint,
    expires-at: uint,
    metadata: (string-ascii 200)
  }
)

;; Trading orders and transactions
(define-map purchase-orders
  { order-id: uint }
  {
    buyer: principal,
    listing-id: uint,
    amount-purchased: uint,
    price-paid: uint,
    marketplace-fee: uint,
    project-funding: uint,
    purchased-at: uint,
    compliance-purpose: (optional (string-ascii 100))
  }
)

;; User balances for different resource types
(define-map user-balances
  { user: principal, resource-type: uint }
  { balance: uint, last-updated: uint }
)

;; Retired credits for compliance
(define-map retired-credits
  { retirement-id: uint }
  {
    user: principal,
    resource-type: uint,
    amount: uint,
    reason: (string-ascii 200),
    retired-at: uint,
    compliance-period: uint,
    certification-hash: (optional (string-ascii 64))
  }
)

;; Price discovery - bonding curve parameters
(define-map resource-prices
  { resource-type: uint }
  {
    current-price: uint,
    total-supply: uint,
    total-demand: uint,
    last-updated: uint,
    price-change-percent: int
  }
)

;; Project funding distribution tracking
(define-map project-funding-pool
  { project-id: uint }
  {
    total-allocated: uint,
    total-distributed: uint,
    last-distribution: uint,
    beneficiary: (optional principal)
  }
)

;; Corporate sustainability reporting
(define-map sustainability-reports
  { company: principal, reporting-period: uint }
  {
    water-credits-purchased: uint,
    forest-credits-purchased: uint,
    biodiversity-tokens-purchased: uint,
    total-investment: uint,
    credits-retired: uint,
    carbon-offset-claimed: uint,
    reported-at: uint
  }
)

;; Marketplace statistics
(define-map daily-stats
  { date: uint }
  {
    trades-count: uint,
    volume-traded: uint,
    average-price: uint,
    active-listings: uint
  }
)

;; public functions
;;

;; Create a new credit listing
(define-public (create-listing
    (resource-type uint)
    (amount uint)
    (price-per-unit uint)
    (expires-in-blocks uint)
    (project-id (optional uint))
    (metadata (string-ascii 200))
  )
  (let (
    (listing-id (var-get next-listing-id))
    (total-price (* amount price-per-unit))
    (expires-at (+ block-height expires-in-blocks))
    (user-balance (get-user-balance tx-sender resource-type))
  )
    (asserts! (<= resource-type RESOURCE_BIODIVERSITY) ERR_INVALID_RESOURCE_TYPE)
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    (asserts! (> price-per-unit u0) ERR_INVALID_PRICE)
    (asserts! (>= user-balance amount) ERR_INSUFFICIENT_BALANCE)
    
    ;; Create the listing
    (map-set credit-listings
      { listing-id: listing-id }
      {
        seller: tx-sender,
        resource-type: resource-type,
        amount: amount,
        price-per-unit: price-per-unit,
        total-price: total-price,
        project-id: project-id,
        status: STATUS_ACTIVE,
        created-at: block-height,
        expires-at: expires-at,
        metadata: metadata
      }
    )
    
    ;; Reserve seller's credits
    (set-user-balance tx-sender resource-type (- user-balance amount))
    
    ;; Update marketplace stats
    (update-daily-stats block-height)
    
    (var-set next-listing-id (+ listing-id u1))
    
    (ok listing-id)
  )
)

;; Purchase credits from a listing
(define-public (purchase-credits
    (listing-id uint)
    (amount-to-buy uint)
    (compliance-purpose (optional (string-ascii 100)))
  )
  (let (
    (listing (unwrap! (map-get? credit-listings { listing-id: listing-id }) ERR_LISTING_NOT_FOUND))
    (order-id (var-get next-order-id))
    (total-cost (* amount-to-buy (get price-per-unit listing)))
    (marketplace-fee (/ (* total-cost MARKETPLACE_FEE_PERCENT) u100))
    (seller-payment (- total-cost marketplace-fee))
    (project-funding (/ (* marketplace-fee FUNDING_DISTRIBUTION_PERCENT) u100))
  )
    (asserts! (not (is-eq tx-sender (get seller listing))) ERR_BUYER_IS_SELLER)
    (asserts! (is-eq (get status listing) STATUS_ACTIVE) ERR_LISTING_NOT_ACTIVE)
    (asserts! (> amount-to-buy u0) ERR_INVALID_AMOUNT)
    (asserts! (<= amount-to-buy (get amount listing)) ERR_INVALID_AMOUNT)
    (asserts! (<= block-height (get expires-at listing)) ERR_LISTING_NOT_ACTIVE)
    
    ;; Process the purchase
    (try! (stx-transfer? total-cost tx-sender (as-contract tx-sender)))
    (try! (as-contract (stx-transfer? seller-payment tx-sender (get seller listing))))
    
    ;; Update buyer's credit balance
    (set-user-balance tx-sender (get resource-type listing) 
      (+ (get-user-balance tx-sender (get resource-type listing)) amount-to-buy))
    
    ;; Update listing or mark as sold
    (if (is-eq amount-to-buy (get amount listing))
      (map-set credit-listings { listing-id: listing-id }
        (merge listing { status: STATUS_SOLD }))
      (map-set credit-listings { listing-id: listing-id }
        (merge listing { amount: (- (get amount listing) amount-to-buy) }))
    )
    
    ;; Record the order
    (map-set purchase-orders
      { order-id: order-id }
      {
        buyer: tx-sender,
        listing-id: listing-id,
        amount-purchased: amount-to-buy,
        price-paid: total-cost,
        marketplace-fee: marketplace-fee,
        project-funding: project-funding,
        purchased-at: block-height,
        compliance-purpose: compliance-purpose
      }
    )
    
    ;; Update statistics
    (update-resource-stats (get resource-type listing) amount-to-buy total-cost)
    (distribute-project-funding (get project-id listing) project-funding)
    
    ;; Update global counters
    (var-set next-order-id (+ order-id u1))
    (var-set total-volume-traded (+ (var-get total-volume-traded) total-cost))
    (var-set total-marketplace-fees (+ (var-get total-marketplace-fees) marketplace-fee))
    
    (ok order-id)
  )
)

;; Retire credits for compliance reporting
(define-public (retire-credits
    (resource-type uint)
    (amount uint)
    (reason (string-ascii 200))
    (compliance-period uint)
    (certification-hash (optional (string-ascii 64)))
  )
  (let (
    (retirement-id (+ (* block-height u1000) (var-get next-order-id))) ;; Simple ID generation
    (user-balance (get-user-balance tx-sender resource-type))
  )
    (asserts! (<= resource-type RESOURCE_BIODIVERSITY) ERR_INVALID_RESOURCE_TYPE)
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    (asserts! (>= user-balance amount) ERR_INSUFFICIENT_BALANCE)
    
    ;; Burn the credits from user's balance
    (set-user-balance tx-sender resource-type (- user-balance amount))
    
    ;; Record the retirement
    (map-set retired-credits
      { retirement-id: retirement-id }
      {
        user: tx-sender,
        resource-type: resource-type,
        amount: amount,
        reason: reason,
        retired-at: block-height,
        compliance-period: compliance-period,
        certification-hash: certification-hash
      }
    )
    
    ;; Update sustainability report
    (update-sustainability-report tx-sender resource-type amount compliance-period)
    
    (ok retirement-id)
  )
)

;; Cancel an active listing
(define-public (cancel-listing (listing-id uint))
  (let (
    (listing (unwrap! (map-get? credit-listings { listing-id: listing-id }) ERR_LISTING_NOT_FOUND))
    (seller-balance (get-user-balance (get seller listing) (get resource-type listing)))
  )
    (asserts! (is-eq tx-sender (get seller listing)) ERR_UNAUTHORIZED)
    (asserts! (is-eq (get status listing) STATUS_ACTIVE) ERR_LISTING_NOT_ACTIVE)
    
    ;; Return credits to seller
    (set-user-balance (get seller listing) (get resource-type listing)
      (+ seller-balance (get amount listing)))
    
    ;; Mark listing as cancelled
    (map-set credit-listings { listing-id: listing-id }
      (merge listing { status: STATUS_CANCELLED }))
    
    (ok true)
  )
)

;; Update price for a resource type (automated price discovery)
(define-public (update-resource-price (resource-type uint))
  (let (
    (current-stats (get-resource-price-data resource-type))
    (supply (get total-supply current-stats))
    (demand (get total-demand current-stats))
    (new-price (calculate-bonding-curve-price supply demand))
    (price-change (calculate-price-change (get current-price current-stats) new-price))
  )
    (asserts! (<= resource-type RESOURCE_BIODIVERSITY) ERR_INVALID_RESOURCE_TYPE)
    
    (map-set resource-prices
      { resource-type: resource-type }
      {
        current-price: new-price,
        total-supply: supply,
        total-demand: demand,
        last-updated: block-height,
        price-change-percent: price-change
      }
    )
    
    (ok new-price)
  )
)

;; Submit corporate sustainability report
(define-public (submit-sustainability-report
    (reporting-period uint)
    (water-purchased uint)
    (forest-purchased uint)
    (biodiversity-purchased uint)
    (total-investment uint)
    (credits-retired uint)
    (carbon-offset-claimed uint)
  )
  (begin
    (map-set sustainability-reports
      { company: tx-sender, reporting-period: reporting-period }
      {
        water-credits-purchased: water-purchased,
        forest-credits-purchased: forest-purchased,
        biodiversity-tokens-purchased: biodiversity-purchased,
        total-investment: total-investment,
        credits-retired: credits-retired,
        carbon-offset-claimed: carbon-offset-claimed,
        reported-at: block-height
      }
    )
    
    (ok true)
  )
)

;; read only functions
;;

;; Get listing details
(define-read-only (get-listing (listing-id uint))
  (map-get? credit-listings { listing-id: listing-id })
)

;; Get purchase order details
(define-read-only (get-order (order-id uint))
  (map-get? purchase-orders { order-id: order-id })
)

;; Get user balance for a resource type
(define-read-only (get-user-balance (user principal) (resource-type uint))
  (default-to u0
    (get balance
      (map-get? user-balances { user: user, resource-type: resource-type })
    )
  )
)

;; Get current resource price data
(define-read-only (get-resource-price-data (resource-type uint))
  (default-to
    {
      current-price: BASE_PRICE,
      total-supply: u0,
      total-demand: u0,
      last-updated: u0,
      price-change-percent: 0
    }
    (map-get? resource-prices { resource-type: resource-type })
  )
)

;; Get marketplace statistics
(define-read-only (get-marketplace-stats)
  {
    total-volume: (var-get total-volume-traded),
    total-fees: (var-get total-marketplace-fees),
    project-funding: (var-get total-project-funding),
    water-traded: (var-get water-credits-traded),
    forest-traded: (var-get forest-credits-traded),
    biodiversity-traded: (var-get biodiversity-tokens-traded),
    next-listing-id: (var-get next-listing-id),
    next-order-id: (var-get next-order-id)
  }
)

;; Get retirement record
(define-read-only (get-retirement (retirement-id uint))
  (map-get? retired-credits { retirement-id: retirement-id })
)

;; Get sustainability report
(define-read-only (get-sustainability-report (company principal) (reporting-period uint))
  (map-get? sustainability-reports { company: company, reporting-period: reporting-period })
)

;; Get daily trading statistics
(define-read-only (get-daily-stats (date uint))
  (map-get? daily-stats { date: date })
)

;; private functions
;;

;; Set user balance for a resource type
(define-private (set-user-balance (user principal) (resource-type uint) (new-balance uint))
  (map-set user-balances
    { user: user, resource-type: resource-type }
    { balance: new-balance, last-updated: block-height }
  )
)

;; Calculate bonding curve price based on supply and demand
(define-private (calculate-bonding-curve-price (supply uint) (demand uint))
  (if (is-eq supply u0)
    BASE_PRICE
    (+ BASE_PRICE (* (/ (* demand PRICE_MULTIPLIER) supply) u10))
  )
)

;; Calculate price change percentage
(define-private (calculate-price-change (old-price uint) (new-price uint))
  (if (is-eq old-price u0)
    0
    (to-int (/ (* (if (> new-price old-price) (- new-price old-price) (- old-price new-price)) u100) old-price))
  )
)

;; Update resource-specific trading statistics
(define-private (update-resource-stats (resource-type uint) (amount uint) (value uint))
  (if (is-eq resource-type RESOURCE_WATER)
    (var-set water-credits-traded (+ (var-get water-credits-traded) amount))
    (if (is-eq resource-type RESOURCE_FOREST)
      (var-set forest-credits-traded (+ (var-get forest-credits-traded) amount))
      (var-set biodiversity-tokens-traded (+ (var-get biodiversity-tokens-traded) amount))
    )
  )
)

;; Distribute funding to conservation projects
(define-private (distribute-project-funding (project-id (optional uint)) (amount uint))
  (match project-id
    pid
    (let (
      (current-funding (default-to
        { total-allocated: u0, total-distributed: u0, last-distribution: u0, beneficiary: none }
        (map-get? project-funding-pool { project-id: pid })
      ))
    )
      (map-set project-funding-pool
        { project-id: pid }
        (merge current-funding {
          total-allocated: (+ (get total-allocated current-funding) amount),
          last-distribution: block-height
        })
      )
      (var-set total-project-funding (+ (var-get total-project-funding) amount))
    )
    true ;; No project ID provided
  )
)

;; Update daily trading statistics
(define-private (update-daily-stats (date uint))
  (let (
    (current-stats (default-to
      { trades-count: u0, volume-traded: u0, average-price: u0, active-listings: u0 }
      (map-get? daily-stats { date: date })
    ))
  )
    (map-set daily-stats
      { date: date }
      (merge current-stats {
        trades-count: (+ (get trades-count current-stats) u1),
        active-listings: (+ (get active-listings current-stats) u1)
      })
    )
  )
)

;; Update corporate sustainability report
(define-private (update-sustainability-report (company principal) (resource-type uint) (amount uint) (period uint))
  (let (
    (current-report (default-to
      {
        water-credits-purchased: u0,
        forest-credits-purchased: u0,
        biodiversity-tokens-purchased: u0,
        total-investment: u0,
        credits-retired: u0,
        carbon-offset-claimed: u0,
        reported-at: block-height
      }
      (map-get? sustainability-reports { company: company, reporting-period: period })
    ))
  )
    (map-set sustainability-reports
      { company: company, reporting-period: period }
      (merge current-report {
        credits-retired: (+ (get credits-retired current-report) amount)
      })
    )
  )
)

