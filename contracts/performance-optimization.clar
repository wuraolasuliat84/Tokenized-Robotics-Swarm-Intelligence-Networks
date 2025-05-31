;; Performance Optimization Contract
;; Enhances swarm intelligence efficiency

(define-constant ERR_UNAUTHORIZED (err u400))
(define-constant ERR_INVALID_METRICS (err u401))
(define-constant ERR_OPTIMIZATION_FAILED (err u402))
(define-constant ERR_SWARM_NOT_FOUND (err u403))

;; Data structures
(define-map performance-metrics
  { swarm-id: uint, metric-id: uint }
  {
    metric-type: (string-ascii 20),
    value: uint,
    timestamp: uint,
    optimal-range-min: uint,
    optimal-range-max: uint
  }
)

(define-map optimization-algorithms
  { algorithm-id: uint }
  {
    name: (string-ascii 30),
    description: (string-ascii 100),
    efficiency-rating: uint,
    applicable-scenarios: (string-ascii 50),
    active: bool
  }
)

(define-map swarm-optimizations
  { swarm-id: uint }
  {
    current-algorithm: uint,
    efficiency-score: uint,
    last-optimization: uint,
    optimization-count: uint,
    performance-trend: int
  }
)

(define-data-var next-metric-id uint u1)
(define-data-var next-algorithm-id uint u1)

;; Record performance metric
(define-public (record-metric
  (swarm-id uint)
  (metric-type (string-ascii 20))
  (value uint)
  (optimal-min uint)
  (optimal-max uint)
)
  (let ((metric-id (var-get next-metric-id)))
    (map-set performance-metrics
      { swarm-id: swarm-id, metric-id: metric-id }
      {
        metric-type: metric-type,
        value: value,
        timestamp: block-height,
        optimal-range-min: optimal-min,
        optimal-range-max: optimal-max
      }
    )
    (var-set next-metric-id (+ metric-id u1))
    (ok metric-id)
  )
)

;; Register optimization algorithm
(define-public (register-algorithm
  (name (string-ascii 30))
  (description (string-ascii 100))
  (efficiency-rating uint)
  (scenarios (string-ascii 50))
)
  (let ((algorithm-id (var-get next-algorithm-id)))
    (map-set optimization-algorithms
      { algorithm-id: algorithm-id }
      {
        name: name,
        description: description,
        efficiency-rating: efficiency-rating,
        applicable-scenarios: scenarios,
        active: true
      }
    )
    (var-set next-algorithm-id (+ algorithm-id u1))
    (ok algorithm-id)
  )
)

;; Apply optimization to swarm
(define-public (optimize-swarm (swarm-id uint) (algorithm-id uint))
  (match (map-get? optimization-algorithms { algorithm-id: algorithm-id })
    algorithm-data
    (let (
      (current-optimization (default-to
        {
          current-algorithm: u0,
          efficiency-score: u50,
          last-optimization: u0,
          optimization-count: u0,
          performance-trend: 0
        }
        (map-get? swarm-optimizations { swarm-id: swarm-id })
      ))
      (new-efficiency (+ (get efficiency-score current-optimization)
                        (/ (get efficiency-rating algorithm-data) u10)))
    )
      (map-set swarm-optimizations
        { swarm-id: swarm-id }
        {
          current-algorithm: algorithm-id,
          efficiency-score: (if (> new-efficiency u100) u100 new-efficiency),
          last-optimization: block-height,
          optimization-count: (+ (get optimization-count current-optimization) u1),
          performance-trend: (if (> new-efficiency (get efficiency-score current-optimization)) 1 -1)
        }
      )
      (ok new-efficiency)
    )
    ERR_OPTIMIZATION_FAILED
  )
)

;; Calculate efficiency score
(define-read-only (calculate-efficiency (swarm-id uint))
  (match (map-get? swarm-optimizations { swarm-id: swarm-id })
    optimization-data
    (let (
      (base-score (get efficiency-score optimization-data))
      (trend-bonus (if (> (get performance-trend optimization-data) 0) u5 u0))
      (experience-bonus (/ (get optimization-count optimization-data) u10))
    )
      (+ base-score trend-bonus experience-bonus)
    )
    u50 ;; Default efficiency for unoptimized swarms
  )
)

;; Get performance analysis
(define-read-only (analyze-performance (swarm-id uint) (metric-type (string-ascii 20)))
  (match (map-get? performance-metrics { swarm-id: swarm-id, metric-id: u1 })
    metric-data
    (let (
      (value (get value metric-data))
      (min-range (get optimal-range-min metric-data))
      (max-range (get optimal-range-max metric-data))
    )
      (if (and (>= value min-range) (<= value max-range))
        "optimal"
        (if (< value min-range) "below-optimal" "above-optimal")
      )
    )
    "no-data"
  )
)

;; Recommend optimization
(define-read-only (recommend-optimization (swarm-id uint))
  (let (
    (current-efficiency (calculate-efficiency swarm-id))
  )
    (if (< current-efficiency u70)
      (some u1) ;; Recommend basic optimization algorithm
      (if (< current-efficiency u90)
        (some u2) ;; Recommend advanced optimization
        none ;; No optimization needed
      )
    )
  )
)

;; Read-only functions
(define-read-only (get-metric (swarm-id uint) (metric-id uint))
  (map-get? performance-metrics { swarm-id: swarm-id, metric-id: metric-id })
)

(define-read-only (get-algorithm (algorithm-id uint))
  (map-get? optimization-algorithms { algorithm-id: algorithm-id })
)

(define-read-only (get-swarm-optimization (swarm-id uint))
  (map-get? swarm-optimizations { swarm-id: swarm-id })
)
