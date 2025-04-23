;; Care Coordination Contract
;; Ensures continuity during transitions

;; Map to store care coordination plans
(define-map care-plans uint
  {
    patient-hash: (buff 32),
    transfer-id: uint,
    care-plan-hash: (buff 32),
    created-by: principal,
    status: (string-ascii 20),
    completed: bool
  }
)

;; Counter for care plan IDs
(define-data-var care-plan-id-counter uint u0)

;; Create a care coordination plan
(define-public (create-care-plan
                (patient-hash (buff 32))
                (transfer-id uint)
                (care-plan-hash (buff 32)))
  (let ((current-id (var-get care-plan-id-counter)))
    (begin
      (var-set care-plan-id-counter (+ current-id u1))
      (ok (map-set care-plans current-id
        {
          patient-hash: patient-hash,
          transfer-id: transfer-id,
          care-plan-hash: care-plan-hash,
          created-by: tx-sender,
          status: "active",
          completed: false
        }
      ))
    )
  )
)

;; Update care plan status
(define-public (update-care-plan-status (care-plan-id uint) (new-status (string-ascii 20)))
  (let ((care-plan (map-get? care-plans care-plan-id)))
    (begin
      (asserts! (is-some care-plan) (err u1))
      (asserts! (is-eq tx-sender (get created-by (unwrap-panic care-plan))) (err u2))
      (ok (map-set care-plans care-plan-id
        (merge (unwrap-panic care-plan) { status: new-status })
      ))
    )
  )
)

;; Mark care plan as completed
(define-public (complete-care-plan (care-plan-id uint))
  (let ((care-plan (map-get? care-plans care-plan-id)))
    (begin
      (asserts! (is-some care-plan) (err u1))
      (asserts! (is-eq tx-sender (get created-by (unwrap-panic care-plan))) (err u2))
      (ok (map-set care-plans care-plan-id
        (merge (unwrap-panic care-plan)
          {
            status: "completed",
            completed: true
          }
        )
      ))
    )
  )
)

;; Get care plan details
(define-read-only (get-care-plan (care-plan-id uint))
  (map-get? care-plans care-plan-id)
)

;; Check if a care plan is active
(define-read-only (is-care-plan-active (care-plan-id uint))
  (let ((care-plan (map-get? care-plans care-plan-id)))
    (and
      (is-some care-plan)
      (is-eq (get status (unwrap-panic care-plan)) "active")
      (not (get completed (unwrap-panic care-plan)))
    )
  )
)
