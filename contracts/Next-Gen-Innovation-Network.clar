(define-constant ERR-NOT-AUTHORIZED (err u401))
(define-constant ERR-INVALID-INPUT (err u400))
(define-constant ERR-INNOVATION-NOT-FOUND (err u404))
(define-constant ERR-PROPOSAL-NOT-FOUND (err u405))
(define-constant ERR-INSUFFICIENT-FUNDS (err u402))
(define-constant ERR-INNOVATION-CLOSED (err u403))
(define-constant ERR-ALREADY-VOTED (err u406))
(define-constant ERR-DEADLINE-PASSED (err u407))
(define-constant ERR-INVALID-STATUS (err u408))
(define-constant ERR-NOT-COLLABORATOR (err u409))
(define-constant ERR-ALREADY-COLLABORATED (err u410))
(define-constant ERR-INSUFFICIENT-REPUTATION (err u411))
(define-constant ERR-FUNDING-GOAL-NOT-MET (err u412))

(define-constant CONTRACT-OWNER tx-sender)

(define-constant STATUS-OPEN u1)
(define-constant STATUS-FUNDING u2)
(define-constant STATUS-DEVELOPMENT u3)
(define-constant STATUS-TESTING u4)
(define-constant STATUS-LAUNCHED u5)
(define-constant STATUS-COMPLETED u6)

(define-constant PROPOSAL-DRAFT u1)
(define-constant PROPOSAL-SUBMITTED u2)
(define-constant PROPOSAL-APPROVED u3)
(define-constant PROPOSAL-FUNDED u4)
(define-constant PROPOSAL-IMPLEMENTED u5)

(define-constant MIN-REPUTATION u25)
(define-constant COLLABORATION-THRESHOLD u5)
(define-constant FUNDING-PERIOD-BLOCKS u2160)

(define-data-var innovation-nonce uint u0)
(define-data-var proposal-nonce uint u0)
(define-data-var platform-fee uint u3)
(define-data-var min-funding-amount uint u100000)

(define-map innovations
  { innovation-id: uint }
  {
    creator: principal,
    title: (string-ascii 120),
    description: (string-ascii 1200),
    category: (string-ascii 60),
    innovation-type: (string-ascii 80),
    target-market: (string-ascii 100),
    funding-goal: uint,
    current-funding: uint,
    deadline: uint,
    created-at: uint,
    status: uint,
    proposal-count: uint,
    collaborator-count: uint,
    selected-proposals: (list 3 uint),
    technology-stack: (list 5 (string-ascii 50)),
    market-potential: uint,
    development-stage: uint
  }
)

(define-map proposals
  { proposal-id: uint }
  {
    innovation-id: uint,
    proposer: principal,
    title: (string-ascii 100),
    description: (string-ascii 1000),
    technical-approach: (string-ascii 800),
    implementation-plan: (string-ascii 600),
    resource-requirements: (string-ascii 400),
    timeline-estimate: uint,
    budget-request: uint,
    submitted-at: uint,
    status: uint,
    vote-count: uint,
    approval-rating: uint,
    collaboration-score: uint
  }
)

(define-map innovation-funding
  { innovation-id: uint, funder: principal }
  {
    amount-funded: uint,
    funded-at: uint,
    funding-tier: uint,
    expected-return: uint
  }
)

(define-map proposal-votes
  { proposal-id: uint, voter: principal }
  {
    vote-value: uint,
    technical-rating: uint,
    feasibility-rating: uint,
    innovation-rating: uint,
    voted-at: uint
  }
)

(define-map collaborations
  { innovation-id: uint, collaborator: principal }
  {
    role: (string-ascii 50),
    contribution-type: (string-ascii 60),
    joined-at: uint,
    reputation-score: uint,
    contribution-value: uint,
    equity-share: uint
  }
)

(define-map innovator-profiles
  { innovator: principal }
  {
    innovations-created: uint,
    proposals-submitted: uint,
    collaborations-joined: uint,
    total-funding-raised: uint,
    success-rate: uint,
    reputation-score: uint,
    expertise-areas: (list 8 (string-ascii 40)),
    network-connections: uint,
    innovation-impact: uint
  }
)

(define-map innovation-milestones
  { innovation-id: uint }
  {
    milestone-count: uint,
    completed-milestones: uint,
    current-phase: (string-ascii 50),
    next-milestone: (string-ascii 100),
    progress-percentage: uint,
    quality-score: uint,
    timeline-adherence: uint
  }
)

(define-public (create-innovation
  (title (string-ascii 120))
  (description (string-ascii 1200))
  (category (string-ascii 60))
  (innovation-type (string-ascii 80))
  (target-market (string-ascii 100))
  (funding-goal uint)
  (deadline-blocks uint)
  (technology-stack (list 5 (string-ascii 50)))
  (market-potential uint)
)
  (let (
    (innovation-id (+ (var-get innovation-nonce) u1))
    (creator tx-sender)
    (deadline (+ stacks-block-height deadline-blocks))
  )
    (asserts! (>= funding-goal (var-get min-funding-amount)) ERR-INSUFFICIENT-FUNDS)
    (asserts! (> deadline-blocks u0) ERR-INVALID-INPUT)
    (asserts! (> (len title) u0) ERR-INVALID-INPUT)
    (asserts! (> (len description) u50) ERR-INVALID-INPUT)
    (asserts! (and (<= market-potential u100) (>= market-potential u1)) ERR-INVALID-INPUT)

    (map-set innovations
      {innovation-id: innovation-id}
      {
        creator: creator,
        title: title,
        description: description,
        category: category,
        innovation-type: innovation-type,
        target-market: target-market,
        funding-goal: funding-goal,
        current-funding: u0,
        deadline: deadline,
        created-at: stacks-block-height,
        status: STATUS-OPEN,
        proposal-count: u0,
        collaborator-count: u0,
        selected-proposals: (list),
        technology-stack: technology-stack,
        market-potential: market-potential,
        development-stage: u1
      }
    )

    (map-set innovation-milestones
      {innovation-id: innovation-id}
      {
        milestone-count: u5,
        completed-milestones: u0,
        current-phase: "Ideation",
        next-milestone: "Complete prototype development",
        progress-percentage: u0,
        quality-score: u75,
        timeline-adherence: u100
      }
    )

    (let (
      (profile (default-to
        {innovations-created: u0, proposals-submitted: u0, collaborations-joined: u0, total-funding-raised: u0, success-rate: u100, reputation-score: u100, expertise-areas: (list), network-connections: u0, innovation-impact: u0}
        (map-get? innovator-profiles {innovator: creator})
      ))
    )
      (map-set innovator-profiles
        {innovator: creator}
        (merge profile {innovations-created: (+ (get innovations-created profile) u1)})
      )
    )

    (var-set innovation-nonce innovation-id)
    (ok innovation-id)
  )
)

(define-public (submit-proposal
  (innovation-id uint)
  (title (string-ascii 100))
  (description (string-ascii 1000))
  (technical-approach (string-ascii 800))
  (implementation-plan (string-ascii 600))
  (resource-requirements (string-ascii 400))
  (timeline-estimate uint)
  (budget-request uint)
)
  (let (
    (proposal-id (+ (var-get proposal-nonce) u1))
    (proposer tx-sender)
    (innovation (unwrap! (map-get? innovations {innovation-id: innovation-id}) ERR-INNOVATION-NOT-FOUND))
    (proposer-profile (default-to
      {innovations-created: u0, proposals-submitted: u0, collaborations-joined: u0, total-funding-raised: u0, success-rate: u100, reputation-score: u100, expertise-areas: (list), network-connections: u0, innovation-impact: u0}
      (map-get? innovator-profiles {innovator: proposer})
    ))
  )
    (asserts! (is-eq (get status innovation) STATUS-OPEN) ERR-INNOVATION-CLOSED)
    (asserts! (< stacks-block-height (get deadline innovation)) ERR-DEADLINE-PASSED)
    (asserts! (>= (get reputation-score proposer-profile) MIN-REPUTATION) ERR-INSUFFICIENT-REPUTATION)
    (asserts! (> (len title) u0) ERR-INVALID-INPUT)
    (asserts! (> (len description) u30) ERR-INVALID-INPUT)
    (asserts! (> timeline-estimate u0) ERR-INVALID-INPUT)
    (asserts! (> budget-request u0) ERR-INVALID-INPUT)

    (map-set proposals
      {proposal-id: proposal-id}
      {
        innovation-id: innovation-id,
        proposer: proposer,
        title: title,
        description: description,
        technical-approach: technical-approach,
        implementation-plan: implementation-plan,
        resource-requirements: resource-requirements,
        timeline-estimate: timeline-estimate,
        budget-request: budget-request,
        submitted-at: stacks-block-height,
        status: PROPOSAL-SUBMITTED,
        vote-count: u0,
        approval-rating: u0,
        collaboration-score: u0
      }
    )

    (map-set innovations
      {innovation-id: innovation-id}
      (merge innovation {proposal-count: (+ (get proposal-count innovation) u1)})
    )

    (map-set innovator-profiles
      {innovator: proposer}
      (merge proposer-profile {proposals-submitted: (+ (get proposals-submitted proposer-profile) u1)})
    )

    (var-set proposal-nonce proposal-id)
    (ok proposal-id)
  )
)

(define-public (fund-innovation
  (innovation-id uint)
  (funding-amount uint)
  (funding-tier uint)
  (expected-return uint)
)
  (let (
    (funder tx-sender)
    (innovation (unwrap! (map-get? innovations {innovation-id: innovation-id}) ERR-INNOVATION-NOT-FOUND))
  )
    (asserts! (or (is-eq (get status innovation) STATUS-OPEN) (is-eq (get status innovation) STATUS-FUNDING)) ERR-INVALID-STATUS)
    (asserts! (< stacks-block-height (get deadline innovation)) ERR-DEADLINE-PASSED)
    (asserts! (> funding-amount u0) ERR-INVALID-INPUT)
    (asserts! (and (>= funding-tier u1) (<= funding-tier u5)) ERR-INVALID-INPUT)

    (try! (stx-transfer? funding-amount funder (as-contract tx-sender)))

    (map-set innovation-funding
      {innovation-id: innovation-id, funder: funder}
      {
        amount-funded: funding-amount,
        funded-at: stacks-block-height,
        funding-tier: funding-tier,
        expected-return: expected-return
      }
    )

    (let (
      (updated-funding (+ (get current-funding innovation) funding-amount))
      (new-status (if (>= updated-funding (get funding-goal innovation)) STATUS-FUNDING STATUS-OPEN))
    )
      (map-set innovations
        {innovation-id: innovation-id}
        (merge innovation {
          current-funding: updated-funding,
          status: new-status
        })
      )
    )

    (ok true)
  )
)

(define-public (vote-on-proposal
  (proposal-id uint)
  (vote-value uint)
  (technical-rating uint)
  (feasibility-rating uint)
  (innovation-rating uint)
)
  (let (
    (voter tx-sender)
    (proposal (unwrap! (map-get? proposals {proposal-id: proposal-id}) ERR-PROPOSAL-NOT-FOUND))
    (innovation (unwrap! (map-get? innovations {innovation-id: (get innovation-id proposal)}) ERR-INNOVATION-NOT-FOUND))
  )
    (asserts! (not (is-eq voter (get proposer proposal))) ERR-NOT-AUTHORIZED)
    (asserts! (is-none (map-get? proposal-votes {proposal-id: proposal-id, voter: voter})) ERR-ALREADY-VOTED)
    (asserts! (and (>= vote-value u1) (<= vote-value u5)) ERR-INVALID-INPUT)
    (asserts! (<= technical-rating u100) ERR-INVALID-INPUT)
    (asserts! (<= feasibility-rating u100) ERR-INVALID-INPUT)
    (asserts! (<= innovation-rating u100) ERR-INVALID-INPUT)

    (map-set proposal-votes
      {proposal-id: proposal-id, voter: voter}
      {
        vote-value: vote-value,
        technical-rating: technical-rating,
        feasibility-rating: feasibility-rating,
        innovation-rating: innovation-rating,
        voted-at: stacks-block-height
      }
    )

    (let (
      (updated-votes (+ (get vote-count proposal) u1))
      (average-rating (/ (+ technical-rating feasibility-rating innovation-rating) u3))
      (updated-approval (/ (+ (* (get approval-rating proposal) (get vote-count proposal)) average-rating) updated-votes))
    )
      (map-set proposals
        {proposal-id: proposal-id}
        (merge proposal {
          vote-count: updated-votes,
          approval-rating: updated-approval
        })
      )
    )

    (ok true)
  )
)

(define-public (join-collaboration
  (innovation-id uint)
  (role (string-ascii 50))
  (contribution-type (string-ascii 60))
  (contribution-value uint)
)
  (let (
    (collaborator tx-sender)
    (innovation (unwrap! (map-get? innovations {innovation-id: innovation-id}) ERR-INNOVATION-NOT-FOUND))
    (collaborator-profile (default-to
      {innovations-created: u0, proposals-submitted: u0, collaborations-joined: u0, total-funding-raised: u0, success-rate: u100, reputation-score: u100, expertise-areas: (list), network-connections: u0, innovation-impact: u0}
      (map-get? innovator-profiles {innovator: collaborator})
    ))
  )
    (asserts! (not (is-eq collaborator (get creator innovation))) ERR-NOT-AUTHORIZED)
    (asserts! (>= (get reputation-score collaborator-profile) MIN-REPUTATION) ERR-INSUFFICIENT-REPUTATION)
    (asserts! (is-none (map-get? collaborations {innovation-id: innovation-id, collaborator: collaborator})) ERR-ALREADY-COLLABORATED)
    (asserts! (> (len role) u0) ERR-INVALID-INPUT)
    (asserts! (> contribution-value u0) ERR-INVALID-INPUT)

    (let (
      (equity-percentage (/ (* contribution-value u100) (get funding-goal innovation)))
    )
      (map-set collaborations
        {innovation-id: innovation-id, collaborator: collaborator}
        {
          role: role,
          contribution-type: contribution-type,
          joined-at: stacks-block-height,
          reputation-score: (get reputation-score collaborator-profile),
          contribution-value: contribution-value,
          equity-share: equity-percentage
        }
      )
    )

    (map-set innovations
      {innovation-id: innovation-id}
      (merge innovation {collaborator-count: (+ (get collaborator-count innovation) u1)})
    )

    (map-set innovator-profiles
      {innovator: collaborator}
      (merge collaborator-profile {
        collaborations-joined: (+ (get collaborations-joined collaborator-profile) u1),
        network-connections: (+ (get network-connections collaborator-profile) u1)
      })
    )

    (ok true)
  )
)

(define-public (approve-proposal
  (innovation-id uint)
  (proposal-id uint)
)
  (let (
    (innovation (unwrap! (map-get? innovations {innovation-id: innovation-id}) ERR-INNOVATION-NOT-FOUND))
    (proposal (unwrap! (map-get? proposals {proposal-id: proposal-id}) ERR-PROPOSAL-NOT-FOUND))
  )
    (asserts! (is-eq tx-sender (get creator innovation)) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get innovation-id proposal) innovation-id) ERR-INVALID-INPUT)
    (asserts! (>= (get approval-rating proposal) u70) ERR-INVALID-STATUS)
    (asserts! (>= (get vote-count proposal) u3) ERR-INVALID-STATUS)

    (map-set proposals
      {proposal-id: proposal-id}
      (merge proposal {status: PROPOSAL-APPROVED})
    )

    (map-set innovations
      {innovation-id: innovation-id}
      (merge innovation {status: STATUS-DEVELOPMENT})
    )

    (ok true)
  )
)

(define-public (update-milestone
  (innovation-id uint)
  (completed-milestone uint)
  (next-milestone-desc (string-ascii 100))
  (progress-percentage uint)
  (quality-score uint)
)
  (let (
    (innovation (unwrap! (map-get? innovations {innovation-id: innovation-id}) ERR-INNOVATION-NOT-FOUND))
    (milestones (unwrap! (map-get? innovation-milestones {innovation-id: innovation-id}) ERR-INNOVATION-NOT-FOUND))
  )
    (asserts! (is-eq tx-sender (get creator innovation)) ERR-NOT-AUTHORIZED)
    (asserts! (<= progress-percentage u100) ERR-INVALID-INPUT)
    (asserts! (<= quality-score u100) ERR-INVALID-INPUT)

    (map-set innovation-milestones
      {innovation-id: innovation-id}
      (merge milestones {
        completed-milestones: completed-milestone,
        next-milestone: next-milestone-desc,
        progress-percentage: progress-percentage,
        quality-score: quality-score
      })
    )

    (let (
      (new-stage (if (>= progress-percentage u80) u5 (get development-stage innovation)))
      (new-status (if (>= progress-percentage u100) STATUS-COMPLETED (get status innovation)))
    )
      (map-set innovations
        {innovation-id: innovation-id}
        (merge innovation {
          development-stage: new-stage,
          status: new-status
        })
      )
    )

    (ok true)
  )
)

(define-public (distribute-rewards
  (innovation-id uint)
)
  (let (
    (innovation (unwrap! (map-get? innovations {innovation-id: innovation-id}) ERR-INNOVATION-NOT-FOUND))
    (creator (get creator innovation))
    (total-funding (get current-funding innovation))
    (platform-fee-amount (/ (* total-funding (var-get platform-fee)) u100))
    (creator-amount (- total-funding platform-fee-amount))
  )
    (asserts! (is-eq tx-sender creator) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status innovation) STATUS-COMPLETED) ERR-INVALID-STATUS)
    (asserts! (>= (get current-funding innovation) (get funding-goal innovation)) ERR-FUNDING-GOAL-NOT-MET)

    (try! (as-contract (stx-transfer? creator-amount tx-sender creator)))

    (let (
      (profile (default-to
        {innovations-created: u0, proposals-submitted: u0, collaborations-joined: u0, total-funding-raised: u0, success-rate: u100, reputation-score: u100, expertise-areas: (list), network-connections: u0, innovation-impact: u0}
        (map-get? innovator-profiles {innovator: creator})
      ))
    )
      (map-set innovator-profiles
        {innovator: creator}
        (merge profile {
          total-funding-raised: (+ (get total-funding-raised profile) total-funding),
          reputation-score: (+ (get reputation-score profile) u50),
          innovation-impact: (+ (get innovation-impact profile) (get market-potential innovation))
        })
      )
    )

    (ok true)
  )
)

(define-public (update-innovator-expertise
  (innovator principal)
  (expertise-areas (list 8 (string-ascii 40)))
)
  (let (
    (profile (default-to
      {innovations-created: u0, proposals-submitted: u0, collaborations-joined: u0, total-funding-raised: u0, success-rate: u100, reputation-score: u100, expertise-areas: (list), network-connections: u0, innovation-impact: u0}
      (map-get? innovator-profiles {innovator: innovator})
    ))
  )
    (asserts! (is-eq tx-sender innovator) ERR-NOT-AUTHORIZED)

    (map-set innovator-profiles
      {innovator: innovator}
      (merge profile {expertise-areas: expertise-areas})
    )

    (ok true)
  )
)

(define-read-only (get-innovation (innovation-id uint))
  (map-get? innovations {innovation-id: innovation-id})
)

(define-read-only (get-proposal (proposal-id uint))
  (map-get? proposals {proposal-id: proposal-id})
)

(define-read-only (get-innovator-profile (innovator principal))
  (map-get? innovator-profiles {innovator: innovator})
)

(define-read-only (get-innovation-funding (innovation-id uint) (funder principal))
  (map-get? innovation-funding {innovation-id: innovation-id, funder: funder})
)

(define-read-only (get-proposal-vote (proposal-id uint) (voter principal))
  (map-get? proposal-votes {proposal-id: proposal-id, voter: voter})
)

(define-read-only (get-collaboration (innovation-id uint) (collaborator principal))
  (map-get? collaborations {innovation-id: innovation-id, collaborator: collaborator})
)

(define-read-only (get-innovation-milestones (innovation-id uint))
  (map-get? innovation-milestones {innovation-id: innovation-id})
)

(define-read-only (get-platform-stats)
  {
    total-innovations: (var-get innovation-nonce),
    total-proposals: (var-get proposal-nonce),
    platform-fee: (var-get platform-fee),
    min-funding-amount: (var-get min-funding-amount),
    min-reputation: MIN-REPUTATION,
    collaboration-threshold: COLLABORATION-THRESHOLD
  }
)

(define-public (set-platform-fee (new-fee uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (<= new-fee u10) ERR-INVALID-INPUT)
    (var-set platform-fee new-fee)
    (ok true)
  )
)

(define-public (set-min-funding (new-min uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (> new-min u0) ERR-INVALID-INPUT)
    (var-set min-funding-amount new-min)
    (ok true)
  )
)

(begin
  (var-set platform-fee u3)
  (var-set min-funding-amount u100000)
)