;; Manufacturer Verification Contract
;; Validates swarm robotics systems and manufacturers

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_MANUFACTURER_NOT_FOUND (err u101))
(define-constant ERR_ALREADY_VERIFIED (err u102))
(define-constant ERR_INVALID_SYSTEM (err u103))

;; Data structures
(define-map manufacturers
  { manufacturer-id: uint }
  {
    name: (string-ascii 50),
    verified: bool,
    certification-level: uint,
    registration-block: uint
  }
)

(define-map robotics-systems
  { system-id: uint }
  {
    manufacturer-id: uint,
    model: (string-ascii 30),
    verified: bool,
    safety-rating: uint,
    max-swarm-size: uint
  }
)

(define-data-var next-manufacturer-id uint u1)
(define-data-var next-system-id uint u1)

;; Register a new manufacturer
(define-public (register-manufacturer (name (string-ascii 50)))
  (let ((manufacturer-id (var-get next-manufacturer-id)))
    (map-set manufacturers
      { manufacturer-id: manufacturer-id }
      {
        name: name,
        verified: false,
        certification-level: u0,
        registration-block: block-height
      }
    )
    (var-set next-manufacturer-id (+ manufacturer-id u1))
    (ok manufacturer-id)
  )
)

;; Verify a manufacturer (only contract owner)
(define-public (verify-manufacturer (manufacturer-id uint) (certification-level uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (match (map-get? manufacturers { manufacturer-id: manufacturer-id })
      manufacturer-data
      (begin
        (map-set manufacturers
          { manufacturer-id: manufacturer-id }
          (merge manufacturer-data { verified: true, certification-level: certification-level })
        )
        (ok true)
      )
      ERR_MANUFACTURER_NOT_FOUND
    )
  )
)

;; Register a robotics system
(define-public (register-system
  (manufacturer-id uint)
  (model (string-ascii 30))
  (safety-rating uint)
  (max-swarm-size uint)
)
  (let ((system-id (var-get next-system-id)))
    (match (map-get? manufacturers { manufacturer-id: manufacturer-id })
      manufacturer-data
      (begin
        (asserts! (get verified manufacturer-data) ERR_MANUFACTURER_NOT_FOUND)
        (map-set robotics-systems
          { system-id: system-id }
          {
            manufacturer-id: manufacturer-id,
            model: model,
            verified: false,
            safety-rating: safety-rating,
            max-swarm-size: max-swarm-size
          }
        )
        (var-set next-system-id (+ system-id u1))
        (ok system-id)
      )
      ERR_MANUFACTURER_NOT_FOUND
    )
  )
)

;; Verify a robotics system
(define-public (verify-system (system-id uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (match (map-get? robotics-systems { system-id: system-id })
      system-data
      (begin
        (map-set robotics-systems
          { system-id: system-id }
          (merge system-data { verified: true })
        )
        (ok true)
      )
      ERR_INVALID_SYSTEM
    )
  )
)

;; Read-only functions
(define-read-only (get-manufacturer (manufacturer-id uint))
  (map-get? manufacturers { manufacturer-id: manufacturer-id })
)

(define-read-only (get-system (system-id uint))
  (map-get? robotics-systems { system-id: system-id })
)

(define-read-only (is-system-verified (system-id uint))
  (match (map-get? robotics-systems { system-id: system-id })
    system-data (get verified system-data)
    false
  )
)
