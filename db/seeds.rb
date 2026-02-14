# frozen_string_literal: true

puts "Seeding database..."

# Admin user
admin_email = ENV.fetch("ADMIN_EMAIL") { Rails.env.production? ? raise("ADMIN_EMAIL required in production") : "admin@example.com" }
admin_password = ENV.fetch("ADMIN_PASSWORD") { Rails.env.production? ? raise("ADMIN_PASSWORD required in production") : "Changeme1" }

admin_display_name = ENV.fetch("ADMIN_DISPLAY_NAME") { "Admin" }

admin = User.find_or_initialize_by(email_address: admin_email)
attrs = {
  display_name: admin_display_name,
  role: :admin,
  active: true,
  confirmed_at: Time.current
}
# Only set password for new records or when explicitly provided via ENV
if admin.new_record? || ENV["ADMIN_PASSWORD"].present?
  attrs[:password] = admin_password
  attrs[:password_confirmation] = admin_password
end
admin.assign_attributes(attrs)
unless admin.save
  raise "Admin user validation failed: #{admin.errors.full_messages.join(', ')}. " \
        "ADMIN_PASSWORD must be at least 8 characters with uppercase, lowercase, and a digit."
end
puts "Admin user created: #{admin.email_address}"

# Config defaults
configs = {
  "default_vat_rate" => "0.21",
  "standard_hours_per_day" => "8",
  "fx_api_provider" => "exchangerate_api",
  "cas_rate" => "0.25",
  "cass_rate" => "0.10",
  "income_tax_rate" => "0.10"
}

configs.each do |key, value|
  Config.find_or_create_by!(key: key) do |c|
    c.value = value
  end
end

# Ensure VAT rate config matches the current allowed rates
Config.set("default_vat_rate", "0.21")

puts "Config defaults seeded."

puts "Seeding complete."

# DEMO DATA: The Brass Tap — 3 carpenters, 1 project (Jan 5 – Feb 6 2026), 3 phases, 8 tasks, 75 daily logs, 13 material entries. Schedule: 25 working days each, 8h/day.

project = Project.find_by(name: "The Brass Tap - Bar & Restaurant Furniture Fit-Out")
admin_user = User.find_by!(role: :admin)

unless project
  puts ""
  puts "Seeding demo data..."

  # Workers
  workers_data = [
    { full_name: "Ion Popescu",      trade: "Carpenter", notes: "Senior carpenter, 15 years experience. Specialises in bar counters and built-in furniture.", gross: 6_500 },
    { full_name: "Andrei Marinescu", trade: "Carpenter", notes: "Mid-level carpenter, 8 years experience. Strong on finishing and detail work.",              gross: 5_500 },
    { full_name: "Mihai Dumitrescu", trade: "Carpenter", notes: "Junior carpenter, 3 years experience. Fast learner, good with CNC and batch production.",    gross: 4_800 }
  ]

  workers = workers_data.map do |wd|
    worker = Worker.find_or_create_by!(full_name: wd[:full_name]) do |w|
      w.trade  = wd[:trade]
      w.notes  = wd[:notes]
      w.active = true
    end

    unless worker.worker_salaries.kept.exists?(effective_from: Date.new(2026, 1, 1))
      worker.worker_salaries.create!(
        gross_monthly_ron: wd[:gross],
        effective_from:    Date.new(2026, 1, 1)
      )
    end

    puts "  Worker: #{worker.full_name} (#{worker.current_salary&.net_monthly_ron&.round(2)} RON net)"
    worker
  end

  ion, andrei, mihai = workers

  # Project
  project = Project.create!(
    name:               "The Brass Tap - Bar & Restaurant Furniture Fit-Out",
    client_name:        "The Brass Tap SRL",
    status:             :active,
    planned_start_date: Date.new(2026, 1, 5),
    planned_end_date:   Date.new(2026, 2, 6),
    description:        "Full custom furniture build and installation for a new bar and restaurant " \
                        "in central Bucharest. Scope includes a 4-metre oak and walnut bar counter " \
                        "with brass foot rail, 8 dining tables, 12 chairs, 3-section banquette " \
                        "seating with leather vinyl upholstery, wall-mounted display shelving, " \
                        "a 72-bottle wine rack, and a glass storage unit. All pieces are bespoke, " \
                        "built from kiln-dried Romanian oak and walnut with a satin polyurethane finish.",
    created_by_user:    admin_user
  )
  puts "  Project: #{project.name}"
else
  puts ""
  puts "Project exists. Adding/updating phases and tasks..."
  ion = Worker.find_by(full_name: "Ion Popescu")
  andrei = Worker.find_by(full_name: "Andrei Marinescu")
  mihai = Worker.find_by(full_name: "Mihai Dumitrescu")
end

if project
  # Phases
  phase_defs = [
    { key: :p1, name: "Preparation & Procurement", start: "2026-01-05", fin: "2026-01-12", priority: :high, status: :done },
    { key: :p2, name: "Construction",              start: "2026-01-13", fin: "2026-02-02", priority: :high, status: :done },
    { key: :p3, name: "Finishing & Installation", start: "2026-02-02", fin: "2026-02-06", priority: :high, status: :in_progress }
  ]

  phases = {}
  phase_defs.each do |pd|
    ph = project.phases.find_or_create_by!(name: pd[:name]) do |phase|
      phase.planned_start_date = Date.parse(pd[:start])
      phase.planned_end_date   = Date.parse(pd[:fin])
      phase.priority           = pd[:priority]
      phase.status             = pd[:status]
    end
    phases[pd[:key]] = ph
    puts "  Phase: #{ph.name} (#{pd[:start]} → #{pd[:fin]}, #{ph.status})"
  end

  # Tasks
  task_defs = [
    { key: :t1, name: "Site Survey & Template Making",  start: "2026-01-05", fin: "2026-01-07", priority: :high,   status: :done,        phase: :p1 },
    { key: :t2, name: "Material Procurement & Prep",    start: "2026-01-08", fin: "2026-01-12", priority: :high,   status: :done,        phase: :p1 },
    { key: :t3, name: "Bar Counter Construction",       start: "2026-01-13", fin: "2026-01-23", priority: :high,   status: :done,        phase: :p2 },
    { key: :t4, name: "Dining Tables (8 units)",        start: "2026-01-13", fin: "2026-01-21", priority: :medium, status: :done,        phase: :p2 },
    { key: :t5, name: "Banquette Seating & Chairs",     start: "2026-01-22", fin: "2026-01-30", priority: :medium, status: :done,        phase: :p2 },
    { key: :t6, name: "Shelving & Wine Racks",          start: "2026-01-26", fin: "2026-02-02", priority: :medium, status: :done,        phase: :p2 },
    { key: :t7, name: "Finishing & Lacquering",         start: "2026-02-02", fin: "2026-02-05", priority: :high,   status: :in_progress, phase: :p3 },
    { key: :t8, name: "On-Site Installation",           start: "2026-02-06", fin: "2026-02-06", priority: :high,   status: :planned,     phase: :p3 }
  ]

  tasks = {}
  task_defs.each do |td|
    t = project.tasks.find_or_initialize_by(name: td[:name])
    t.assign_attributes(
      planned_start_date: Date.parse(td[:start]),
      planned_end_date:   Date.parse(td[:fin]),
      priority:           td[:priority],
      status:             td[:status],
      phase:              phases[td[:phase]]
    )
    t.save!
    tasks[td[:key]] = t
    puts "  Task: #{t.name} (#{td[:start]} → #{td[:fin]}, #{t.status}, phase: #{phases[td[:phase]]&.name || 'none'})"
  end

  # Helper: working days (Mon–Fri) in date range
  def self.working_days(from, to)
    (from..to).select { |d| (1..5).include?(d.wday) }
  end

  # Daily Logs — worker schedules with per-day scope

  # T1 scope
  t1_scope = {
    ion: [
      "Measured bar area dimensions and floor levelness. Documented column positions and electrical outlet locations.",
      "Made full-size cardboard templates for banquette seating alcoves. Verified wall angles — two corners slightly out of square (3mm over 2m).",
      "Final measurements review and cross-check against architect drawings. Noted 15mm discrepancy on east wall, documented for workaround."
    ],
    andrei: [
      "Photographed the restaurant dining area from multiple angles. Recorded ceiling height variations and window placements.",
      "Measured and templated window bench areas. Sketched shelving wall elevation with client on site.",
      "Compiled measurement sheets and photo documentation into project folder. Prepared preliminary cut lists for lumber order."
    ],
    mihai: [
      "Created cardboard templates for the bar counter curved profile. Checked wall straightness with 2m spirit level and laser.",
      "Built full-size MDF template for bar counter top curve. Marked pipe runs and access panel positions on floor plan.",
      "Constructed scale mock-up of bar counter from cardboard for client approval. Confirmed design details and brass rail placement."
    ]
  }

  # T2 scope
  t2_scope = {
    ion: [
      "Visited Lemnexim lumber yard. Hand-selected and graded 3.5 m³ of kiln-dried oak planks — rejected 4 boards with excessive twist.",
      "Received lumber delivery at workshop. Stacked and stickered oak for acclimatisation. Inspected each board for hidden defects with moisture meter.",
      "Planed oak stock to 45mm thickness on the thicknesser. Jointed edges for glue-up panels. Set aside 12 best boards for table tops."
    ],
    andrei: [
      "Selected 1.2 m³ of walnut stock at Lemnexim for decorative bar front panels. Checked moisture content on every board — all below 10%.",
      "Rough-cut walnut boards to approximate dimensions on the bandsaw. Set aside best figured pieces for visible bar front panels.",
      "Thicknessed walnut panels to 25mm. Cut MDF backing panels to size on table saw. Prepared edge banding strips from walnut offcuts."
    ],
    mihai: [
      "Purchased MDF panels, hardware, screws, adhesives, and sundries from Dedeman. Organised delivery to workshop for next morning.",
      "Organised hardware inventory on arrival. Sorted screws, brackets, hinges, and fittings into labelled bins for each upcoming task.",
      "Sharpened all hand tools — chisels, planes, marking gauges. Calibrated table saw fence and jointer tables. Set up dust extraction routing."
    ]
  }

  # T3 scope
  t3_scope = {
    ion: [
      "Began bar counter frame construction. Cut and assembled the main structural skeleton from 90×45mm oak using mortise-and-tenon joints.",
      "Continued frame assembly. Installed cross-braces and leveling feet. Checked frame — square within 1mm tolerance over 4m length.",
      "Edge-glued oak boards for the main counter top. Four panels of 600×2400mm each, using biscuits for alignment, clamped with pipe clamps.",
      "Flattened glued-up counter top panels with router sled jig. Achieved ±0.5mm flatness across each 2.4m panel. Sanded to 120 grit.",
      "Joined counter top sections with Domino tenons and loose tongues. Dry-fitted the full 4m top to verify seamless alignment at joints.",
      "Fitted brass foot rail mounting brackets to bar front. Drilled and tapped for M8 bolts at 600mm centres. Test-fitted rail section.",
      "Mounted the full 4m brass foot rail. Polished solder joints at bracket connections. Rail sits at 250mm from floor as per spec.",
      "Fitted the assembled counter top to the frame. Secured with pocket screws from underneath, allowing 8mm slots for seasonal wood movement.",
      "Final bar counter assembly checks. Adjusted all four leveling feet. Sanded every exposed surface to 180 grit ready for finishing."
    ],
    andrei: [
      "Prepared bar counter base panels from MDF. Cut access doors for plumbing and electrical runs behind the bar. Hinged with 110° concealed hinges.",
      "Laminated walnut veneer onto MDF front panels using PVA and vacuum bag press. Trimmed excess with flush-trim router bit.",
      "Routed decorative ogee profile on bar front panel edges. Fitted solid brass corner trims to all exposed MDF edges.",
      "Assembled the bar's lower storage shelving unit. Fitted adjustable shelf pins on 32mm system and applied iron-on walnut edge banding.",
      "Installed bar front panels onto frame with French cleats. Aligned walnut grain direction across panels for visual continuity.",
      "Built the speed rail and bottle display shelf from oak. Routed grooves for the stainless steel glass rack inserts.",
      "Installed under-counter LED strip channel in routed aluminium extrusion. Cut cable management grooves in rear panels for clean wiring.",
      "Attached the drink rail along the customer side. Routed 10mm-deep channel for the rubber bar mat along the bartender service side.",
      "Completed bar counter detail work. Installed removable service access panels with magnetic catches. Final hardware check on all doors."
    ]
  }

  # T4 scope
  t4_scope = {
    mihai: [
      "Began dining table production. Edge-glued oak boards for first 4 table tops (800×1200mm each). Alternated growth ring orientation to minimise cupping.",
      "Turned 16 tapered table legs on the lathe from 80mm oak blanks. Achieved consistent 70mm-to-45mm taper. Sanded each to 180 grit on the lathe.",
      "Flattened first 4 glued table tops with the router sled. Glued up remaining 4 table tops using the same alternating grain technique, clamped overnight.",
      "Cut mortises in all 8 table tops for leg attachment using the Domino joiner. Consistent 8×40mm tenon slots at each corner, 60mm from edges.",
      "Assembled first 4 dining tables. Fitted legs with cross-rails, glued tenon joints, and installed adjustable leveling glides in each leg foot.",
      "Flattened remaining 4 table tops. Assembled tables 5 through 8 using same joinery method. All 8 tables now structurally complete and stable.",
      "Sanded all 8 dining tables progressively from 120 to 180 grit. Eased all edges with 3mm roundover bit. Filled minor knot holes with tinted oak filler."
    ]
  }

  # T5 scope
  t5_scope = {
    mihai: [
      "Started banquette seating frames. Cut oak pieces for 3 bench sections (each 1800mm long). Prepared mortise-and-tenon frame joints.",
      "Assembled all 3 banquette frames with reinforced pocket-hole joinery. Built hinged plywood seat tops for under-seat storage access.",
      "Fitted angled back supports to banquettes at 5° recline for comfort. Routed channels along top edges for upholstery staple attachment.",
      "Cut upholstery foam to size for all 3 banquette seat cushions and back panels. Glued 50mm foam to 12mm plywood bases with spray adhesive.",
      "Wrapped banquette seat and back panels in leather vinyl fabric. Stapled underneath with 10mm crown staples at 25mm spacing for a tight finish.",
      "Fitted completed banquette sections to their wall-mounting brackets. Verified level and consistent 2mm gap between sections. Adjusted feet.",
      "Final banquette adjustments. Added solid oak end caps, kick panels, and decorative trim. Cleaned and inspected all upholstery edges."
    ],
    andrei: [
      "Began chair production. Cut oak stock for 12 dining chair frames — side rails, back uprights, and stretchers. Batch-cut to identical length.",
      "Turned all 48 chair legs (4 per chair) on the lathe. Cut mortises for side rail and stretcher joints using the Domino joiner.",
      "Assembled first 6 chairs. Glued all joints with PVA, clamped, and checked for square. Applied webbing straps to seat frames for cushion support.",
      "Assembled remaining 6 chairs. Cut 12 seat blanks from 12mm plywood. Glued foam pads and wrapped first 6 seats in leather vinyl fabric.",
      "Completed upholstery on remaining 6 chair seats. Attached all 12 padded seats to frames with hanger bolts for easy removal and re-upholstery."
    ]
  }

  # T6 scope
  t6_scope = {
    ion: [
      "Installed heavy-duty French cleat battens on the back bar wall using 8mm masonry anchors at 400mm centres. Verified level across the 4m span.",
      "Built 3 floating display shelves from 30mm oak with hidden cleat slots routed into the back edges. Chamfered front edges for a clean profile.",
      "Constructed wine rack lattice from 20×40mm oak strips arranged in a diamond pattern. The rack holds 72 bottles in 6 rows of 12 diamonds.",
      "Assembled the upper glass storage rack from oak and stainless steel rods. Installed T-moulding strips creating 4 channels for stemware hanging.",
      "Built the lower bar storage cabinet with two sliding doors on soft-close runners. Fitted magnetic catches and internal adjustable shelves.",
      "Final shelving and rack installation. Mounted all units onto their French cleats. Tested weight capacity with loaded bottles — well within spec."
    ]
  }

  # T7 scope
  t7_scope = {
    andrei: [
      "Began finish sanding all furniture pieces. Started with bar counter — progressed from 180 grit to 220 grit across all surfaces.",
      "Applied first polyurethane satin coat to bar counter using a foam roller for even coverage. Set up drying area with 3-hour intervals.",
      "Lightly sanded bar counter between coats with 320 grit. Applied second polyurethane coat. Touched up any thin spots and drip marks.",
      "Applied third and final coat to bar counter and all bar components. Inspected under raking light for orange peel and drips — none found."
    ],
    mihai: [
      "Sanded all 8 dining tables to 220 grit. Wiped down with tack cloth to remove all dust. Applied first coat of polyurethane satin finish.",
      "Lightly sanded all table surfaces between coats with 320 grit. Applied second polyurethane coat. Ensured even coverage on legs and stretchers.",
      "Applied third coat to all 8 dining tables. Buffed cured surfaces lightly with 0000 steel wool for a perfectly smooth satin feel.",
      "Applied finish coats to all banquette woodwork and 12 chair frames/legs. Final quality inspection on every piece of seating furniture."
    ],
    ion: [
      "Sanded shelving, wine racks, and glass storage unit to 220 grit. Applied first coat of polyurethane satin finish to all bar-back pieces.",
      "Applied second coat to all shelving and wine rack pieces. Sanded 12 chair frames between coats with 320 grit. Applied chair finish coat.",
      "Applied final polyurethane coat to all remaining shelving and storage pieces. Full quality inspection of every finished surface in the workshop."
    ]
  }

  # T8 scope
  t8_scope = {
    ion: [
      "Loaded truck and transported all furniture to The Brass Tap. Installed shelving, wine racks, and glass storage on French cleats. Mounted bar counter in position and shimmed level."
    ],
    andrei: [
      "Positioned and leveled all 8 dining tables in the restaurant floor plan. Installed 3 banquette sections and secured to wall brackets with lag bolts."
    ],
    mihai: [
      "Placed all 12 dining chairs. Performed final touch-ups on minor transit scuffs with touch-up pen and satin spray. Client walkthrough and preliminary sign-off."
    ]
  }

  # --------------------------------------------------------------------------
  # Worker schedule: maps each worker to their task sequence
  # --------------------------------------------------------------------------
  ion_schedule = [
    { task: :t1, from: "2026-01-05", to: "2026-01-07" },
    { task: :t2, from: "2026-01-08", to: "2026-01-12" },
    { task: :t3, from: "2026-01-13", to: "2026-01-23" },
    { task: :t6, from: "2026-01-26", to: "2026-02-02" },
    { task: :t7, from: "2026-02-03", to: "2026-02-05" },
    { task: :t8, from: "2026-02-06", to: "2026-02-06" }
  ]

  andrei_schedule = [
    { task: :t1, from: "2026-01-05", to: "2026-01-07" },
    { task: :t2, from: "2026-01-08", to: "2026-01-12" },
    { task: :t3, from: "2026-01-13", to: "2026-01-23" },
    { task: :t5, from: "2026-01-26", to: "2026-01-30" },
    { task: :t7, from: "2026-02-02", to: "2026-02-05" },
    { task: :t8, from: "2026-02-06", to: "2026-02-06" }
  ]

  mihai_schedule = [
    { task: :t1, from: "2026-01-05", to: "2026-01-07" },
    { task: :t2, from: "2026-01-08", to: "2026-01-12" },
    { task: :t4, from: "2026-01-13", to: "2026-01-21" },
    { task: :t5, from: "2026-01-22", to: "2026-01-30" },
    { task: :t7, from: "2026-02-02", to: "2026-02-05" },
    { task: :t8, from: "2026-02-06", to: "2026-02-06" }
  ]

  # Scope lookup by task key
  all_scope = {
    t1: t1_scope, t2: t2_scope, t3: t3_scope, t4: t4_scope,
    t5: t5_scope, t6: t6_scope, t7: t7_scope, t8: t8_scope
  }

  # Create daily logs for one worker (only if workers exist)
  if ion && andrei && mihai
    create_logs = lambda do |worker, schedule, worker_key|
      total = 0
      schedule.each do |entry|
        task_key = entry[:task]
        next unless tasks[task_key]
        days = working_days(Date.parse(entry[:from]), Date.parse(entry[:to]))
        scope_array = all_scope[task_key][worker_key]

        days.each_with_index do |date, idx|
          note = scope_array[idx] || scope_array.last
          DailyLog.find_or_create_by!(
            project:         project,
            task:            tasks[task_key],
            worker:          worker,
            log_date:        date
          ) do |log|
            log.hours_worked    = 8.0
            log.scope           = note
            log.created_by_user = admin_user
          end
          total += 1
        end
      end
      total
    end

    ion_logs    = create_logs.call(ion,    ion_schedule,    :ion)
    andrei_logs = create_logs.call(andrei, andrei_schedule, :andrei)
    mihai_logs  = create_logs.call(mihai,  mihai_schedule,  :mihai)
    puts "  Daily logs: Ion=#{ion_logs}, Andrei=#{andrei_logs}, Mihai=#{mihai_logs} (total=#{ion_logs + andrei_logs + mihai_logs})"
  end

  # --------------------------------------------------------------------------
  # Material Entries
  # --------------------------------------------------------------------------
  materials = [
    { desc: "Oak lumber (stejar), kiln-dried, 50mm planks",       qty: 3.5,  unit: "m³",    cost: 2_800.00, supplier: "Lemnexim SRL",      date: "2026-01-08", task: :t2 },
    { desc: "Walnut lumber (nuc), kiln-dried, 30mm boards",       qty: 1.2,  unit: "m³",    cost: 4_500.00, supplier: "Lemnexim SRL",      date: "2026-01-08", task: :t2 },
    { desc: "MDF panels 2440×1220×18mm",                          qty: 24,   unit: "sheet", cost: 145.00,   supplier: "Dedeman",           date: "2026-01-08", task: :t2 },
    { desc: "Brass foot rail tube ∅50mm, polished",               qty: 6,    unit: "m",     cost: 320.00,   supplier: "MetalCraft SRL",    date: "2026-01-13", task: :t3 },
    { desc: "Wood screws assorted (4×30 to 6×80), box of 500",    qty: 8,    unit: "box",   cost: 45.00,    supplier: "Dedeman",           date: "2026-01-13", task: :t3 },
    { desc: "PVA wood glue D3 waterproof, 1kg bottle",            qty: 12,   unit: "kg",    cost: 28.00,    supplier: "Dedeman",           date: "2026-01-13", task: :t3 },
    { desc: "Upholstery foam, high-density 50mm",                 qty: 8,    unit: "m²",    cost: 65.00,    supplier: "Tapițerie Express", date: "2026-01-22", task: :t5 },
    { desc: "Leather vinyl fabric, dark brown, 140cm wide",       qty: 12,   unit: "m",     cost: 120.00,   supplier: "Tapițerie Express", date: "2026-01-22", task: :t5 },
    { desc: "French cleats, aluminium, 600mm length",             qty: 20,   unit: "pcs",   cost: 18.00,    supplier: "Dedeman",           date: "2026-01-26", task: :t6 },
    { desc: "Steel brackets, heavy-duty L-shape 100×100mm",       qty: 30,   unit: "pcs",   cost: 12.00,    supplier: "Dedeman",           date: "2026-01-26", task: :t6 },
    { desc: "Sandpaper sheets assorted (80/120/180/220/320 grit)", qty: 50,  unit: "sheet", cost: 4.50,     supplier: "Dedeman",           date: "2026-02-02", task: :t7 },
    { desc: "Polyurethane satin finish, 1L tin",                   qty: 15,  unit: "L",     cost: 85.00,    supplier: "Bochemie RO",       date: "2026-02-02", task: :t7 },
    { desc: "Furniture transport to site (full truck)",            qty: 1,    unit: "trip",  cost: 800.00,   supplier: "Lemnexim SRL",      date: "2026-02-06", task: :t8 }
  ]

  materials.each do |m|
    MaterialEntry.find_or_create_by!(
      project: project,
      date: Date.parse(m[:date]),
      description: m[:desc]
    ) do |entry|
      entry.task                 = m[:task] ? tasks[m[:task]] : nil
      entry.quantity             = m[:qty]
      entry.unit                 = m[:unit]
      entry.unit_cost_ex_vat_ron = m[:cost]
      entry.vat_rate             = 0.21
      entry.created_by_user      = admin_user
    end
  end
  puts "  Material entries: #{materials.size}"

  # --------------------------------------------------------------------------
  # Currency Rates (RON → GBP, working days Jan 5 – Feb 6)
  # --------------------------------------------------------------------------
  # Realistic range: ~0.1710–0.1730 GBP per 1 RON (≈ 5.78–5.85 RON per GBP)
  base_rate = 0.1720
  working_days(Date.new(2026, 1, 5), Date.new(2026, 2, 6)).each_with_index do |date, idx|
    # Small daily fluctuation seeded deterministically
    fluctuation = Math.sin(idx * 0.7) * 0.0008 + Math.cos(idx * 1.3) * 0.0004
    rate = (base_rate + fluctuation).round(8)

    CurrencyRate.find_or_create_by!(
      date:           date,
      base_currency:  "RON",
      quote_currency: "GBP"
    ) do |cr|
      cr.rate   = rate
      cr.source = "demo_seed"
    end
  end
  puts "  Currency rates seeded for project period."

  # --------------------------------------------------------------------------
  # Summary
  # --------------------------------------------------------------------------
  worker_days = project.daily_logs.kept.group(:worker_id, :log_date).count.size
  daily_rates_sum = project.daily_logs.kept
    .select(:worker_id, :log_date).distinct
    .includes(worker: :worker_salaries)
    .sum { |dl| dl.worker.daily_rate_cached(dl.log_date) || 0 }
  total_materials = project.material_entries.kept.sum(:total_cost_inc_vat_ron)
  puts ""
  puts "  Demo data summary:"
  puts "    Phases:          #{phases.size}"
  puts "    Tasks:           #{tasks.size}"
  puts "    Daily logs:      #{project.daily_logs.count}"
  puts "    Material entries: #{project.material_entries.count}"
  puts "    Worker-days:      #{worker_days}"
  puts "    Est. labour cost: #{daily_rates_sum.round(2)} RON"
  puts "    Material cost:    #{total_materials.round(2)} RON (inc VAT)"
  puts ""
  puts "Demo data seeded successfully."
end
