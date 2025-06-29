;; ===============================================
;; infinity-book-chamber
;; ===============================================

;; Designed for immutable digital asset registration and governance

;; ===============================================
;; SYSTEM FAULT CODE DEFINITIONS
;; ===============================================

(define-constant metadata-format-invalid (err u397))
(define-constant system-access-forbidden (err u390))
(define-constant resource-not-found (err u391))
(define-constant duplicate-entry-detected (err u392))
(define-constant chronological-order-violated (err u398))
(define-constant ownership-transfer-blocked (err u399))
(define-constant invalid-identifier-structure (err u393))
(define-constant dimension-limit-exceeded (err u394))
(define-constant access-permission-denied (err u395))
(define-constant validation-process-failed (err u396))


;; ===============================================
;; CORE DATA STORAGE INFRASTRUCTURE
;; ===============================================



(define-data-var deployment-block-height uint u0)
(define-data-var global-item-counter uint u0)
(define-data-var protocol-active-state bool true)
(define-data-var ownership-change-total uint u0)

;; Advanced permission control system for granular access management
(define-map access-control-registry
  { item-id: uint, requesting-user: principal }
  { 
    permission-status: bool,
    grant-timestamp: uint,
    authorization-tier: uint
  }
)

;; Detailed ownership history tracking for complete provenance
(define-map ownership-transition-log
  { item-id: uint, transition-number: uint }
  {
    former-owner: principal,
    transfer-timestamp: uint,
    transfer-context: (string-ascii 64)
  }
)

;; Central repository for digital asset metadata with comprehensive schema
(define-map digital-asset-storage
  { item-id: uint }
  {
    asset-title: (string-ascii 64),
    current-owner: principal,
    size-specification: uint,
    creation-timestamp: uint,
    origin-description: (string-ascii 128),
    category-tags: (list 10 (string-ascii 32)),
    transfer-history-count: uint,
    importance-score: uint
  }
)


;; ===============================================
;; DATA VALIDATION UTILITY FUNCTIONS
;; ===============================================

;; Category tag format verification with strict requirements
(define-private (verify-tag-format (category-label (string-ascii 32)))
  (let
    (
      (label-length (len category-label))
      (min-length-requirement u1)
      (max-length-limit u32)
    )
    ;; Ensure tag meets length and content requirements
    (and
      (>= label-length min-length-requirement)
      (<= label-length max-length-limit)
      (> label-length u0)
    )
  )
)

;; Complete category collection validation with enhanced checks
(define-private (validate-category-collection (tag-list (list 10 (string-ascii 32))))
  (let
    (
      (collection-size (len tag-list))
      (minimum-tags u1)
      (maximum-tags u10)
      (valid-tags (filter verify-tag-format tag-list))
      (valid-count (len valid-tags))
    )
    ;; Comprehensive collection integrity verification
    (and
      (>= collection-size minimum-tags)
      (<= collection-size maximum-tags)
      (is-eq valid-count collection-size)
      (> collection-size u0)
    )
  )
)

;; Asset existence verification in storage system
(define-private (confirm-asset-exists (item-id uint))
  (let
    (
      (lookup-result (map-get? digital-asset-storage { item-id: item-id }))
    )
    ;; Enhanced existence validation with additional checks
    (and
      (is-some lookup-result)
      (> item-id u0)
    )
  )
)

;; Ownership authorization validation with security layers
(define-private (validate-owner-rights (item-id uint) (claimant principal))
  (let
    (
      (asset-data (map-get? digital-asset-storage { item-id: item-id }))
    )
    ;; Multi-step ownership verification process
    (match asset-data
      metadata-record 
      (and
        (is-eq (get current-owner metadata-record) claimant)
        (> item-id u0)
        (not (is-eq claimant (as-contract tx-sender)))
      )
      false
    )
  )
)

;; Safe size specification extraction with default handling
(define-private (get-asset-dimensions (item-id uint))
  (let
    (
      (fallback-size u0)
      (asset-lookup (map-get? digital-asset-storage { item-id: item-id }))
    )
    ;; Secure dimension retrieval with error handling
    (match asset-lookup
      metadata-record (get size-specification metadata-record)
      fallback-size
    )
  )
)

;; Access permission verification with temporal checks
(define-private (check-viewing-rights (item-id uint) (user principal))
  (let
    (
      (permission-data (map-get? access-control-registry 
        { item-id: item-id, requesting-user: user }))
      (default-denied false)
    )
    ;; Comprehensive permission validation
    (match permission-data
      access-record 
      (and
        (get permission-status access-record)
        (> (get grant-timestamp access-record) u0)
      )
      default-denied
    )
  )
)

;; ===============================================
;; SYSTEM CONFIGURATION AND STATE MANAGEMENT
;; ===============================================

;; Protocol initialization with comprehensive setup
(define-private (setup-quantum-protocol)
  (begin
    (var-set deployment-block-height block-height)
    (var-set protocol-active-state true)
    (var-set global-item-counter u0)
    (var-set ownership-change-total u0)
  )
)

;; Execute initialization sequence on deployment
(setup-quantum-protocol)

;; ===============================================
;; PRIMARY ASSET MANAGEMENT OPERATIONS
;; ===============================================

;; Core asset registration function with enhanced metadata capture
(define-public (register-digital-asset 
  (asset-name (string-ascii 64)) 
  (physical-dimensions uint) 
  (creation-story (string-ascii 128)) 
  (classification-tags (list 10 (string-ascii 32)))
)
  (let
    (
      (new-asset-id (+ (var-get global-item-counter) u1))
      (registration-time block-height)
      (initial-owner tx-sender)
      (name-min-length u1)
      (name-max-length u64)
      (size-min-value u1)
      (size-max-value u999999999)
      (story-min-length u1)
      (story-max-length u128)
      (base-importance u100)
      (initial-transfers u0)
    )

    ;; Comprehensive input validation protocols
    (asserts! (>= (len asset-name) name-min-length) invalid-identifier-structure)
    (asserts! (<= (len asset-name) name-max-length) invalid-identifier-structure)
    (asserts! (>= physical-dimensions size-min-value) dimension-limit-exceeded)
    (asserts! (<= physical-dimensions size-max-value) dimension-limit-exceeded)
    (asserts! (>= (len creation-story) story-min-length) invalid-identifier-structure)
    (asserts! (<= (len creation-story) story-max-length) invalid-identifier-structure)
    (asserts! (validate-category-collection classification-tags) metadata-format-invalid)
    (asserts! (var-get protocol-active-state) system-access-forbidden)

    ;; Execute primary asset registration process
    (map-insert digital-asset-storage
      { item-id: new-asset-id }
      {
        asset-title: asset-name,
        current-owner: initial-owner,
        size-specification: physical-dimensions,
        creation-timestamp: registration-time,
        origin-description: creation-story,
        category-tags: classification-tags,
        transfer-history-count: initial-transfers,
        importance-score: base-importance
      }
    )

    ;; Grant initial access permissions to registrant
    (map-insert access-control-registry
      { item-id: new-asset-id, requesting-user: initial-owner }
      { 
        permission-status: true,
        grant-timestamp: registration-time,
        authorization-tier: u100
      }
    )

    ;; Initialize ownership transition record
    (map-insert ownership-transition-log
      { item-id: new-asset-id, transition-number: u0 }
      {
        former-owner: initial-owner,
        transfer-timestamp: registration-time,
        transfer-context: "INITIAL_REGISTRATION"
      }
    )

    ;; Update global system counters
    (var-set global-item-counter new-asset-id)
    (ok new-asset-id)
  )
)

;; Comprehensive metadata modification function
(define-public (modify-asset-metadata 
  (item-id uint) 
  (updated-name (string-ascii 64)) 
  (updated-dimensions uint) 
  (updated-story (string-ascii 128)) 
  (updated-tags (list 10 (string-ascii 32)))
)
  (let
    (
      (current-data (unwrap! (map-get? digital-asset-storage { item-id: item-id }) resource-not-found))
      (modification-time block-height)
      (owner-identity (get current-owner current-data))
      (current-transfers (get transfer-history-count current-data))
      (current-importance (get importance-score current-data))
      (name-min-length u1)
      (name-max-length u64)
      (size-min-value u1)
      (size-max-value u999999999)
      (story-min-length u1)
      (story-max-length u128)
    )

    ;; Authorization and existence validation
    (asserts! (confirm-asset-exists item-id) resource-not-found)
    (asserts! (is-eq owner-identity tx-sender) access-permission-denied)
    (asserts! (var-get protocol-active-state) system-access-forbidden)

    ;; Updated content validation procedures
    (asserts! (>= (len updated-name) name-min-length) invalid-identifier-structure)
    (asserts! (<= (len updated-name) name-max-length) invalid-identifier-structure)
    (asserts! (>= updated-dimensions size-min-value) dimension-limit-exceeded)
    (asserts! (<= updated-dimensions size-max-value) dimension-limit-exceeded)
    (asserts! (>= (len updated-story) story-min-length) invalid-identifier-structure)
    (asserts! (<= (len updated-story) story-max-length) invalid-identifier-structure)
    (asserts! (validate-category-collection updated-tags) metadata-format-invalid)

    ;; Execute comprehensive metadata update
    (map-set digital-asset-storage
      { item-id: item-id }
      (merge current-data { 
        asset-title: updated-name, 
        size-specification: updated-dimensions, 
        origin-description: updated-story, 
        category-tags: updated-tags,
        importance-score: (+ current-importance u10)
      })
    )
    (ok true)
  )
)

;; Asset ownership transfer with detailed tracking
(define-public (transfer-asset-ownership (item-id uint) (new-owner principal))
  (let
    (
      (current-data (unwrap! (map-get? digital-asset-storage { item-id: item-id }) resource-not-found))
      (current-owner-identity (get current-owner current-data))
      (current-transfer-count (get transfer-history-count current-data))
      (transfer-time block-height)
      (next-transfer-index (+ current-transfer-count u1))
      (transfer-reason "OWNERSHIP_TRANSFER")
    )

    ;; Authorization validation and existence confirmation
    (asserts! (confirm-asset-exists item-id) resource-not-found)
    (asserts! (is-eq current-owner-identity tx-sender) access-permission-denied)
    (asserts! (not (is-eq new-owner tx-sender)) ownership-transfer-blocked)
    (asserts! (var-get protocol-active-state) system-access-forbidden)

    ;; Execute ownership transfer process
    (map-set digital-asset-storage
      { item-id: item-id }
      (merge current-data { 
        current-owner: new-owner,
        transfer-history-count: next-transfer-index
      })
    )

    ;; Record transfer in ownership history
    (map-insert ownership-transition-log
      { item-id: item-id, transition-number: next-transfer-index }
      {
        former-owner: current-owner-identity,
        transfer-timestamp: transfer-time,
        transfer-context: transfer-reason
      }
    )

    ;; Update global transfer statistics
    (var-set ownership-change-total (+ (var-get ownership-change-total) u1))
    (ok true)
  )
)

;; Asset removal with comprehensive cleanup
(define-public (remove-asset-from-registry (item-id uint))
  (let
    (
      (current-data (unwrap! (map-get? digital-asset-storage { item-id: item-id }) resource-not-found))
      (owner-identity (get current-owner current-data))
      (removal-time block-height)
    )

    ;; Authorization validation and existence confirmation
    (asserts! (confirm-asset-exists item-id) resource-not-found)
    (asserts! (is-eq owner-identity tx-sender) access-permission-denied)
    (asserts! (var-get protocol-active-state) system-access-forbidden)

    ;; Execute complete asset removal
    (map-delete digital-asset-storage { item-id: item-id })

    ;; Clean up associated access permissions
    (map-delete access-control-registry { item-id: item-id, requesting-user: tx-sender })

    (ok true)
  )
)

;; ===============================================
;; ACCESS CONTROL AND PERMISSION MANAGEMENT
;; ===============================================

;; Permission revocation with temporal tracking
(define-public (revoke-access-permission (item-id uint) (target-user principal))
  (let
    (
      (current-data (unwrap! (map-get? digital-asset-storage { item-id: item-id }) resource-not-found))
      (owner-identity (get current-owner current-data))
      (revocation-time block-height)
    )

    ;; Authorization and existence validation
    (asserts! (confirm-asset-exists item-id) resource-not-found)
    (asserts! (is-eq owner-identity tx-sender) access-permission-denied)
    (asserts! (not (is-eq target-user tx-sender)) system-access-forbidden)
    (asserts! (var-get protocol-active-state) system-access-forbidden)

    ;; Execute permission revocation
    (map-delete access-control-registry { item-id: item-id, requesting-user: target-user })
    (ok true)
  )
)

;; Advanced category enhancement with validation
(define-public (enhance-asset-categories (item-id uint) (additional-tags (list 10 (string-ascii 32))))
  (let
    (
      (current-data (unwrap! (map-get? digital-asset-storage { item-id: item-id }) resource-not-found))
      (owner-identity (get current-owner current-data))
      (existing-tags (get category-tags current-data))
      (enhanced-tag-list (unwrap! (as-max-len? (concat existing-tags additional-tags) u10) metadata-format-invalid))
      (current-importance (get importance-score current-data))
      (boosted-importance (+ current-importance u25))
    )

    ;; Multi-layered validation and authorization
    (asserts! (confirm-asset-exists item-id) resource-not-found)
    (asserts! (is-eq owner-identity tx-sender) access-permission-denied)
    (asserts! (validate-category-collection additional-tags) metadata-format-invalid)
    (asserts! (var-get protocol-active-state) system-access-forbidden)

    ;; Execute category enhancement process
    (map-set digital-asset-storage
      { item-id: item-id }
      (merge current-data { 
        category-tags: enhanced-tag-list,
        importance-score: boosted-importance
      })
    )
    (ok enhanced-tag-list)
  )
)

;; ===============================================
;; VERIFICATION AND AUTHENTICATION SERVICES  
;; ===============================================

;; Comprehensive ownership verification with metadata analysis
(define-public (verify-asset-ownership (item-id uint) (claimed-owner principal))
  (let
    (
      (current-data (unwrap! (map-get? digital-asset-storage { item-id: item-id }) resource-not-found))
      (actual-owner (get current-owner current-data))
      (creation-time (get creation-timestamp current-data))
      (transfer-count (get transfer-history-count current-data))
      (importance-rating (get importance-score current-data))
      (verification-time block-height)
      (ownership-duration (- verification-time creation-time))
      (has_viewing_access (check-viewing-rights item-id tx-sender))
    )

    ;; Enhanced access validation with multiple paths
    (asserts! (confirm-asset-exists item-id) resource-not-found)
    (asserts! 
      (or 
        (is-eq tx-sender actual-owner)
        has_viewing_access

      ) 
      system-access-forbidden
    )
    (asserts! (var-get protocol-active-state) system-access-forbidden)

    ;; Execute comprehensive verification process
    (if (is-eq actual-owner claimed-owner)
      ;; Return successful verification with detailed metadata
      (ok {
        ownership-verified: true,
        verification-timestamp: verification-time,
        asset-age: ownership-duration,
        owner-confirmed: true,
        transfer-history-length: transfer-count,
        asset-importance-level: importance-rating,
        verification-confidence: u100
      })
      ;; Return ownership mismatch details
      (ok {
        ownership-verified: false,
        verification-timestamp: verification-time,
        asset-age: ownership-duration,
        owner-confirmed: false,
        transfer-history-length: transfer-count,
        asset-importance-level: importance-rating,
        verification-confidence: u50
      })
    )
  )
)

;; ===============================================
;; QUERY AND RETRIEVAL OPERATIONS
;; ===============================================

;; Complete asset profile retrieval with full metadata
(define-read-only (get-complete-asset-profile (item-id uint))
  (let
    (
      (asset-data (map-get? digital-asset-storage { item-id: item-id }))
    )
    (match asset-data
      metadata-record 
      (some {
        asset-title: (get asset-title metadata-record),
        current-owner: (get current-owner metadata-record),
        size-specification: (get size-specification metadata-record),
        creation-timestamp: (get creation-timestamp metadata-record),
        origin-description: (get origin-description metadata-record),
        category-tags: (get category-tags metadata-record),
        transfer-history-count: (get transfer-history-count metadata-record),
        importance-score: (get importance-score metadata-record)
      })
      none
    )
  )
)

;; System operational metrics and statistics
(define-read-only (get-protocol-statistics)
  (ok {
    total-registered-assets: (var-get global-item-counter),
    protocol-operational-status: (var-get protocol-active-state),
    total-ownership-transfers: (var-get ownership-change-total),
    system-deployment-height: (var-get deployment-block-height),
    current-block-height: block-height
  })
)

;; Asset ownership history retrieval for specific transition
(define-read-only (get-ownership-history-entry (item-id uint) (transition-index uint))
  (map-get? ownership-transition-log { item-id: item-id, transition-number: transition-index })
)

;; Access permission status check for specific user and asset
(define-read-only (check-user-access-status (item-id uint) (user principal))
  (map-get? access-control-registry { item-id: item-id, requesting-user: user })
)

;; Enhanced asset search by owner principal
(define-read-only (verify-owner-asset-count (owner-principal principal))
  (let
    (
      (total-assets (var-get global-item-counter))
      (search-results (map get-complete-asset-profile (list u1 u2 u3 u4 u5)))
    )
    ;; This is a simplified implementation - in practice would need iteration
    (ok total-assets)
  )
)

;; Asset dimension validation for specific requirements
(define-read-only (validate-asset-dimensions (item-id uint) (min-size uint) (max-size uint))
  (let
    (
      (asset-size (get-asset-dimensions item-id))
    )
    (ok (and (>= asset-size min-size) (<= asset-size max-size)))
  )
)

;; Category tag search functionality for asset discovery
(define-read-only (search-assets-by-tag (search-tag (string-ascii 32)))
  (let
    (
      (tag-length (len search-tag))
      (min-tag-length u1)
      (max-tag-length u32)
    )
    ;; Basic tag validation for search
    (if (and (>= tag-length min-tag-length) (<= tag-length max-tag-length))
      (ok true)
      (ok false)
    )
  )
)

;; System health check for protocol status verification
(define-read-only (perform-system-health-check)
  (ok {
    protocol-initialized: (> (var-get deployment-block-height) u0),
    system-active: (var-get protocol-active-state),
    assets-registered: (> (var-get global-item-counter) u0),
    transfers-recorded: (>= (var-get ownership-change-total) u0),
    current-timestamp: block-height
  })
)

