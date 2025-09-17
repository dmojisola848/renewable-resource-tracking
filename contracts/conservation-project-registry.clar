
;; title: conservation-project-registry
;; version: 1.0.0
;; summary: Environmental conservation project registration and verification system
;; description: Manages environmental conservation project registration, verification,
;; credit issuance, biodiversity tracking, sponsor relationships, and impact reporting

;; traits
;;

;; token definitions
;;

;; constants
;;
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_PROJECT_NOT_FOUND (err u101))
(define-constant ERR_PROJECT_ALREADY_EXISTS (err u102))
(define-constant ERR_INVALID_VERIFICATION_STAGE (err u103))
(define-constant ERR_ALREADY_VERIFIED (err u104))
(define-constant ERR_INSUFFICIENT_FUNDS (err u105))
(define-constant ERR_INVALID_BIODIVERSITY_SCORE (err u106))
(define-constant ERR_SPONSOR_NOT_FOUND (err u107))
(define-constant ERR_INVALID_AMOUNT (err u108))

(define-constant CONTRACT_OWNER tx-sender)
(define-constant MINIMUM_BIODIVERSITY_SCORE u1)
(define-constant MAXIMUM_BIODIVERSITY_SCORE u100)
(define-constant BASE_CREDIT_MULTIPLIER u10)

;; Project verification stages
(define-constant STAGE_SUBMITTED u0)
(define-constant STAGE_UNDER_REVIEW u1)
(define-constant STAGE_VERIFIED u2)
(define-constant STAGE_REJECTED u3)

;; data vars
;;
(define-data-var next-project-id uint u1)
(define-data-var next-sponsor-id uint u1)
(define-data-var total-credits-issued uint u0)
(define-data-var total-projects-registered uint u0)
(define-data-var total-verified-projects uint u0)

;; data maps
;;
;; Project registry with comprehensive metadata
(define-map projects
  { project-id: uint }
  {
    owner: principal,
    name: (string-ascii 100),
    description: (string-ascii 500),
    location: (string-ascii 100),
    project-type: (string-ascii 50), ;; water, forest, biodiversity
    verification-stage: uint,
    biodiversity-score: uint,
    total-funding-received: uint,
    credits-issued: uint,
    created-at: uint,
    verified-at: (optional uint),
    verifier: (optional principal)
  }
)

;; Project verification history
(define-map project-verifications
  { project-id: uint, verification-id: uint }
  {
    verifier: principal,
    stage: uint,
    comments: (string-ascii 300),
    timestamp: uint
  }
)

;; Sponsor registry
(define-map sponsors
  { sponsor-id: uint }
  {
    sponsor: principal,
    name: (string-ascii 100),
    total-funded: uint,
    projects-supported: uint,
    created-at: uint
  }
)

;; Sponsor-project funding relationships
(define-map sponsor-funding
  { sponsor-id: uint, project-id: uint }
  {
    amount: uint,
    funded-at: uint,
    funding-purpose: (string-ascii 200)
  }
)

;; Credit issuance tracking
(define-map credit-issuances
  { project-id: uint, issuance-id: uint }
  {
    credits-amount: uint,
    biodiversity-multiplier: uint,
    issued-at: uint,
    issued-by: principal
  }
)

;; Environmental impact metrics
(define-map impact-reports
  { project-id: uint, report-id: uint }
  {
    carbon-offset: uint,
    water-conserved: uint,
    biodiversity-improvement: uint,
    ecosystem-health-score: uint,
    reporting-period: uint,
    reported-at: uint,
    reporter: principal
  }
)

;; Authorized verifiers
(define-map authorized-verifiers
  { verifier: principal }
  { authorized: bool, authorized-at: uint }
)

;; public functions
;;

;; Register a new conservation project
(define-public (register-project 
    (name (string-ascii 100))
    (description (string-ascii 500))
    (location (string-ascii 100))
    (project-type (string-ascii 50))
    (initial-biodiversity-score uint)
  )
  (let (
    (project-id (var-get next-project-id))
  )
    (asserts! (and (> initial-biodiversity-score u0) (<= initial-biodiversity-score u100)) ERR_INVALID_BIODIVERSITY_SCORE)
    
    (map-set projects
      { project-id: project-id }
      {
        owner: tx-sender,
        name: name,
        description: description,
        location: location,
        project-type: project-type,
        verification-stage: STAGE_SUBMITTED,
        biodiversity-score: initial-biodiversity-score,
        total-funding-received: u0,
        credits-issued: u0,
        created-at: block-height,
        verified-at: none,
        verifier: none
      }
    )
    
    (var-set next-project-id (+ project-id u1))
    (var-set total-projects-registered (+ (var-get total-projects-registered) u1))
    
    (ok project-id)
  )
)

;; Update project verification stage (only authorized verifiers)
(define-public (update-verification-stage
    (project-id uint)
    (new-stage uint)
    (comments (string-ascii 300))
  )
  (let (
    (project (unwrap! (map-get? projects { project-id: project-id }) ERR_PROJECT_NOT_FOUND))
    (verification-id (+ project-id (* block-height u1000))) ;; Simple ID generation
  )
    (asserts! (is-authorized-verifier tx-sender) ERR_UNAUTHORIZED)
    (asserts! (<= new-stage STAGE_REJECTED) ERR_INVALID_VERIFICATION_STAGE)
    
    ;; Update project stage
    (map-set projects
      { project-id: project-id }
      (merge project {
        verification-stage: new-stage,
        verified-at: (if (is-eq new-stage STAGE_VERIFIED) (some block-height) (get verified-at project)),
        verifier: (if (is-eq new-stage STAGE_VERIFIED) (some tx-sender) (get verifier project))
      })
    )
    
    ;; Record verification history
    (map-set project-verifications
      { project-id: project-id, verification-id: verification-id }
      {
        verifier: tx-sender,
        stage: new-stage,
        comments: comments,
        timestamp: block-height
      }
    )
    
    ;; Update verified projects counter
    (if (is-eq new-stage STAGE_VERIFIED)
      (var-set total-verified-projects (+ (var-get total-verified-projects) u1))
      true
    )
    
    (ok true)
  )
)

;; Issue credits for verified projects
(define-public (issue-credits
    (project-id uint)
    (base-credits uint)
  )
  (let (
    (project (unwrap! (map-get? projects { project-id: project-id }) ERR_PROJECT_NOT_FOUND))
    (biodiversity-multiplier (get biodiversity-score project))
    (final-credits (* base-credits (/ biodiversity-multiplier BASE_CREDIT_MULTIPLIER)))
    (issuance-id (+ project-id (* block-height u100)))
  )
    (asserts! (is-authorized-verifier tx-sender) ERR_UNAUTHORIZED)
    (asserts! (is-eq (get verification-stage project) STAGE_VERIFIED) ERR_INVALID_VERIFICATION_STAGE)
    (asserts! (> base-credits u0) ERR_INVALID_AMOUNT)
    
    ;; Update project credits
    (map-set projects
      { project-id: project-id }
      (merge project {
        credits-issued: (+ (get credits-issued project) final-credits)
      })
    )
    
    ;; Record credit issuance
    (map-set credit-issuances
      { project-id: project-id, issuance-id: issuance-id }
      {
        credits-amount: final-credits,
        biodiversity-multiplier: biodiversity-multiplier,
        issued-at: block-height,
        issued-by: tx-sender
      }
    )
    
    (var-set total-credits-issued (+ (var-get total-credits-issued) final-credits))
    
    (ok final-credits)
  )
)

;; Register a sponsor
(define-public (register-sponsor (name (string-ascii 100)))
  (let (
    (sponsor-id (var-get next-sponsor-id))
  )
    (map-set sponsors
      { sponsor-id: sponsor-id }
      {
        sponsor: tx-sender,
        name: name,
        total-funded: u0,
        projects-supported: u0,
        created-at: block-height
      }
    )
    
    (var-set next-sponsor-id (+ sponsor-id u1))
    
    (ok sponsor-id)
  )
)

;; Fund a project (sponsors only)
(define-public (fund-project
    (sponsor-id uint)
    (project-id uint)
    (amount uint)
    (purpose (string-ascii 200))
  )
  (let (
    (project (unwrap! (map-get? projects { project-id: project-id }) ERR_PROJECT_NOT_FOUND))
    (sponsor (unwrap! (map-get? sponsors { sponsor-id: sponsor-id }) ERR_SPONSOR_NOT_FOUND))
  )
    (asserts! (is-eq tx-sender (get sponsor sponsor)) ERR_UNAUTHORIZED)
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    
    ;; Update project funding
    (map-set projects
      { project-id: project-id }
      (merge project {
        total-funding-received: (+ (get total-funding-received project) amount)
      })
    )
    
    ;; Update sponsor info
    (map-set sponsors
      { sponsor-id: sponsor-id }
      (merge sponsor {
        total-funded: (+ (get total-funded sponsor) amount),
        projects-supported: (+ (get projects-supported sponsor) u1)
      })
    )
    
    ;; Record funding relationship
    (map-set sponsor-funding
      { sponsor-id: sponsor-id, project-id: project-id }
      {
        amount: amount,
        funded-at: block-height,
        funding-purpose: purpose
      }
    )
    
    (ok true)
  )
)

;; Submit environmental impact report
(define-public (submit-impact-report
    (project-id uint)
    (carbon-offset uint)
    (water-conserved uint)
    (biodiversity-improvement uint)
    (ecosystem-health-score uint)
    (reporting-period uint)
  )
  (let (
    (project (unwrap! (map-get? projects { project-id: project-id }) ERR_PROJECT_NOT_FOUND))
    (report-id (+ project-id (* block-height u10)))
  )
    (asserts! (is-eq tx-sender (get owner project)) ERR_UNAUTHORIZED)
    (asserts! (<= ecosystem-health-score u100) ERR_INVALID_BIODIVERSITY_SCORE)
    
    (map-set impact-reports
      { project-id: project-id, report-id: report-id }
      {
        carbon-offset: carbon-offset,
        water-conserved: water-conserved,
        biodiversity-improvement: biodiversity-improvement,
        ecosystem-health-score: ecosystem-health-score,
        reporting-period: reporting-period,
        reported-at: block-height,
        reporter: tx-sender
      }
    )
    
    (ok report-id)
  )
)

;; Authorize verifier (contract owner only)
(define-public (authorize-verifier (verifier principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    
    (map-set authorized-verifiers
      { verifier: verifier }
      { authorized: true, authorized-at: block-height }
    )
    
    (ok true)
  )
)

;; read only functions
;;

;; Get project details
(define-read-only (get-project (project-id uint))
  (map-get? projects { project-id: project-id })
)

;; Get sponsor details
(define-read-only (get-sponsor (sponsor-id uint))
  (map-get? sponsors { sponsor-id: sponsor-id })
)

;; Get funding relationship
(define-read-only (get-sponsor-funding (sponsor-id uint) (project-id uint))
  (map-get? sponsor-funding { sponsor-id: sponsor-id, project-id: project-id })
)

;; Get impact report
(define-read-only (get-impact-report (project-id uint) (report-id uint))
  (map-get? impact-reports { project-id: project-id, report-id: report-id })
)

;; Get credit issuance
(define-read-only (get-credit-issuance (project-id uint) (issuance-id uint))
  (map-get? credit-issuances { project-id: project-id, issuance-id: issuance-id })
)

;; Get platform statistics
(define-read-only (get-platform-stats)
  {
    total-projects: (var-get total-projects-registered),
    verified-projects: (var-get total-verified-projects),
    total-credits-issued: (var-get total-credits-issued),
    next-project-id: (var-get next-project-id),
    next-sponsor-id: (var-get next-sponsor-id)
  }
)

;; Check if user is authorized verifier
(define-read-only (is-authorized-verifier (verifier principal))
  (default-to false
    (get authorized
      (map-get? authorized-verifiers { verifier: verifier })
    )
  )
)

;; Get project verification status
(define-read-only (get-verification-status (project-id uint))
  (match (map-get? projects { project-id: project-id })
    project
    (some {
      stage: (get verification-stage project),
      verified-at: (get verified-at project),
      verifier: (get verifier project)
    })
    none
  )
)

;; private functions
;;

;; Calculate credits based on biodiversity score
(define-private (calculate-credits (base-amount uint) (biodiversity-score uint))
  (* base-amount (/ biodiversity-score BASE_CREDIT_MULTIPLIER))
)

