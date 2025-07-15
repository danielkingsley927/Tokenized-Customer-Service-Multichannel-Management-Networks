;; Experience Optimization Contract
;; Optimizes multichannel customer experiences

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u500))
(define-constant ERR-OPTIMIZATION-NOT-FOUND (err u501))
(define-constant ERR-INVALID-INPUT (err u502))
(define-constant ERR-INSUFFICIENT-DATA (err u503))

;; Data Variables
(define-data-var next-optimization-id uint u1)
(define-data-var total-optimizations uint u0)

;; Data Maps
(define-map optimizations
  { optimization-id: uint }
  {
    name: (string-ascii 50),
    optimization-type: (string-ascii 30),
    target-metric: (string-ascii 30),
    current-value: uint,
    target-value: uint,
    status: (string-ascii 20),
    created-at: uint,
    updated-at: uint
  }
)

(define-map experience-metrics
  { metric-id: uint }
  {
    metric-name: (string-ascii 50),
    channel-id: uint,
    value: uint,
    trend: (string-ascii 20),
    benchmark: uint,
    last-updated: uint
  }
)

(define-map optimization-recommendations
  { optimization-id: uint }
  {
    recommendations: (list 10 {
      action: (string-ascii 100),
      impact-score: uint,
      effort-level: uint,
      priority: uint
    })
  }
)

(define-map customer-journey-analysis
  { analysis-id: uint }
  {
    customer-segment: (string-ascii 30),
    journey-stage: (string-ascii 30),
    touchpoints: (list 10 uint),
    pain-points: (list 5 (string-ascii 100)),
    satisfaction-score: uint,
    completion-rate: uint
  }
)

;; Public Functions

;; Create optimization plan
(define-public (create-optimization
  (name (string-ascii 50))
  (optimization-type (string-ascii 30))
  (target-metric (string-ascii 30))
  (current-value uint)
  (target-value uint))
  (let
    (
      (optimization-id (var-get next-optimization-id))
    )
    (asserts! (> (len name) u0) ERR-INVALID-INPUT)
    (asserts! (> target-value current-value) ERR-INVALID-INPUT)

    (map-set optimizations
      { optimization-id: optimization-id }
      {
        name: name,
        optimization-type: optimization-type,
        target-metric: target-metric,
        current-value: current-value,
        target-value: target-value,
        status: "active",
        created-at: block-height,
        updated-at: block-height
      }
    )

    (var-set next-optimization-id (+ optimization-id u1))
    (var-set total-optimizations (+ (var-get total-optimizations) u1))

    (ok optimization-id)
  )
)

;; Update experience metric
(define-public (update-experience-metric
  (metric-id uint)
  (metric-name (string-ascii 50))
  (channel-id uint)
  (value uint)
  (trend (string-ascii 20))
  (benchmark uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (> (len metric-name) u0) ERR-INVALID-INPUT)

    (map-set experience-metrics
      { metric-id: metric-id }
      {
        metric-name: metric-name,
        channel-id: channel-id,
        value: value,
        trend: trend,
        benchmark: benchmark,
        last-updated: block-height
      }
    )

    (ok true)
  )
)

;; Add optimization recommendations
(define-public (add-optimization-recommendations
  (optimization-id uint)
  (recommendations (list 10 {
    action: (string-ascii 100),
    impact-score: uint,
    effort-level: uint,
    priority: uint
  })))
  (let
    (
      (optimization (unwrap! (map-get? optimizations { optimization-id: optimization-id }) ERR-OPTIMIZATION-NOT-FOUND))
    )
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)

    (map-set optimization-recommendations
      { optimization-id: optimization-id }
      { recommendations: recommendations }
    )

    (ok true)
  )
)

;; Update optimization progress
(define-public (update-optimization-progress (optimization-id uint) (current-value uint) (status (string-ascii 20)))
  (let
    (
      (optimization (unwrap! (map-get? optimizations { optimization-id: optimization-id }) ERR-OPTIMIZATION-NOT-FOUND))
    )
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)

    (map-set optimizations
      { optimization-id: optimization-id }
      (merge optimization {
        current-value: current-value,
        status: status,
        updated-at: block-height
      })
    )

    (ok true)
  )
)

;; Analyze customer journey
(define-public (analyze-customer-journey
  (analysis-id uint)
  (customer-segment (string-ascii 30))
  (journey-stage (string-ascii 30))
  (touchpoints (list 10 uint))
  (pain-points (list 5 (string-ascii 100)))
  (satisfaction-score uint)
  (completion-rate uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (<= satisfaction-score u100) ERR-INVALID-INPUT)
    (asserts! (<= completion-rate u100) ERR-INVALID-INPUT)

    (map-set customer-journey-analysis
      { analysis-id: analysis-id }
      {
        customer-segment: customer-segment,
        journey-stage: journey-stage,
        touchpoints: touchpoints,
        pain-points: pain-points,
        satisfaction-score: satisfaction-score,
        completion-rate: completion-rate
      }
    )

    (ok true)
  )
)

;; Read-only Functions

;; Get optimization details
(define-read-only (get-optimization (optimization-id uint))
  (map-get? optimizations { optimization-id: optimization-id })
)

;; Get experience metric
(define-read-only (get-experience-metric (metric-id uint))
  (map-get? experience-metrics { metric-id: metric-id })
)

;; Get optimization recommendations
(define-read-only (get-optimization-recommendations (optimization-id uint))
  (map-get? optimization-recommendations { optimization-id: optimization-id })
)

;; Get customer journey analysis
(define-read-only (get-customer-journey-analysis (analysis-id uint))
  (map-get? customer-journey-analysis { analysis-id: analysis-id })
)

;; Calculate optimization progress
(define-read-only (calculate-optimization-progress (optimization-id uint))
  (match (map-get? optimizations { optimization-id: optimization-id })
    optimization
      (let
        (
          (current (get current-value optimization))
          (target (get target-value optimization))
          (initial (get current-value optimization))
        )
        (if (> target initial)
          (some (/ (* (- current initial) u100) (- target initial)))
          (some u0)
        )
      )
    none
  )
)

;; Get total optimizations count
(define-read-only (get-total-optimizations)
  (var-get total-optimizations)
)

;; Check optimization status
(define-read-only (get-optimization-status (optimization-id uint))
  (match (map-get? optimizations { optimization-id: optimization-id })
    optimization (some (get status optimization))
    none
  )
)
