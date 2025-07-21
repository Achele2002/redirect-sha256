;; Redirect SHA256 Goal Verification
;; A decentralized goal tracking system using SHA256 for secure, verifiable goal management

;; =======================================
;; Constants and Error Definitions
;; =======================================
(define-constant contract-admin tx-sender)

;; Standardized error codes
(define-constant ERR-NOT-AUTHORIZED (err u200))
(define-constant ERR-GOAL-NOT-FOUND (err u201))
(define-constant ERR-MILESTONE-NOT-FOUND (err u202))
(define-constant ERR-GOAL-ALREADY-EXISTS (err u203))
(define-constant ERR-GOAL-COMPLETED (err u204))
(define-constant ERR-INVALID-VERIFICATION (err u205))

;; Visibility settings
(define-constant VISIBILITY-PUBLIC u1)
(define-constant VISIBILITY-PRIVATE u2)

;; =======================================
;; Data Storage
;; =======================================

;; Store goal details mapped by unique identifier
(define-map goal-registry
  {
    creator: principal,
    goal-hash: (buff 32)  ;; SHA256 hash of goal details
  }
  {
    title: (string-ascii 100),
    description: (string-utf8 500),
    created-at: uint,
    completed-at: (optional uint),
    visibility: uint,
    verifier: (optional principal)
  }
)

;; Track milestone progress for goals
(define-map milestone-tracking
  {
    creator: principal,
    goal-hash: (buff 32),
    milestone-id: uint
  }
  {
    title: (string-ascii 100),
    completed: bool,
    completed-at: (optional uint),
    verification-hash: (optional (buff 32))
  }
)

;; =======================================
;; Private Utility Functions
;; =======================================

;; Validate visibility setting
(define-private (is-valid-visibility (setting uint))
  (or 
    (is-eq setting VISIBILITY-PUBLIC)
    (is-eq setting VISIBILITY-PRIVATE)
  )
)

;; Check goal creator authorization
(define-private (is-goal-creator (creator principal) (goal-hash (buff 32)))
  (is-eq tx-sender creator)
)

;; =======================================
;; Read-Only Functions
;; =======================================

;; Retrieve goal details securely
(define-read-only (get-goal-details (creator principal) (goal-hash (buff 32)))
  (let 
    (
      (goal-data (map-get? goal-registry {creator: creator, goal-hash: goal-hash}))
    )
    (if (is-some goal-data)
      (let 
        (
          (unwrapped-goal (unwrap-panic goal-data))
          (visibility (get visibility unwrapped-goal))
        )
        (if (or 
              (is-eq visibility VISIBILITY-PUBLIC)
              (is-eq tx-sender creator)
            )
          (ok unwrapped-goal)
          (err ERR-NOT-AUTHORIZED)
        )
      )
      (err ERR-GOAL-NOT-FOUND)
    )
  )
)

;; =======================================
;; Public Management Functions
;; =======================================

;; Update goal visibility setting
(define-public (modify-goal-visibility (goal-hash (buff 32)) (new-visibility uint))
  (let 
    (
      (creator tx-sender)
      (goal-data (unwrap! 
        (map-get? goal-registry {creator: creator, goal-hash: goal-hash}) 
        (err ERR-GOAL-NOT-FOUND)
      ))
    )
    ;; Authorization and validation checks
    (asserts! (is-goal-creator creator goal-hash) (err ERR-NOT-AUTHORIZED))
    (asserts! (is-valid-visibility new-visibility) (err ERR-INVALID-VERIFICATION))
    
    ;; Update visibility
    (map-set goal-registry
      {creator: creator, goal-hash: goal-hash}
      (merge goal-data {visibility: new-visibility})
    )
    
    (ok true)
  )
)