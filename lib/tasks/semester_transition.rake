# frozen_string_literal: true

namespace :semester do
  desc "Simulate semester transition (officer turnover, event cleanup, attendance reset, member management)"
  task transition: :environment do
    puts "\n" + "="*80
    puts "SEMESTER TRANSITION SIMULATION"
    puts "="*80 + "\n"
    
    # Ensure we have a super admin to perform actions
    super_admin = User.super_admins.first
    unless super_admin
      puts "❌ Error: No super admin found. Creating one..."
      super_admin = User.create!(
        email: "admin@example.com",
        full_name: "System Admin",
        uid: "admin_#{SecureRandom.hex(8)}",
        role: 'super_admin',
        approval_status: 'approved'
      )
      puts "✅ Created super admin: #{super_admin.email}"
    end
    
    puts "\n📊 Current System Status:"
    puts "   Users: #{User.count} (Officers: #{User.officers.count}, Members: #{User.where(role: 'user').count})"
    puts "   Events: #{Event.count} (Past: #{Event.past.count}, Upcoming: #{Event.upcoming.count})"
    puts "   Attendances: #{Attendance.count}"
    puts "   Demerits: #{Demerit.count}"
    
    # Step 1: Officer Turnover
    puts "\n" + "-"*80
    puts "STEP 1: OFFICER TURNOVER"
    puts "-"*80
    officer_turnover(super_admin)
    
    # Step 2: Archive/Delete Old Events
    puts "\n" + "-"*80
    puts "STEP 2: ARCHIVE OLD EVENTS"
    puts "-"*80
    archive_old_events
    
    # Step 3: Reset Attendance History
    puts "\n" + "-"*80
    puts "STEP 3: RESET ATTENDANCE & DEMERITS"
    puts "-"*80
    reset_attendance_history
    
    # Step 4: Member Management
    puts "\n" + "-"*80
    puts "STEP 4: MEMBER MANAGEMENT"
    puts "-"*80
    manage_members(super_admin)
    
    # Step 5: Create New Semester Events
    puts "\n" + "-"*80
    puts "STEP 5: CREATE NEW SEMESTER EVENTS"
    puts "-"*80
    create_new_semester_events
    
    # Final Summary
    puts "\n" + "="*80
    puts "TRANSITION COMPLETE - NEW SEMESTER STATUS"
    puts "="*80
    puts "\n📊 Updated System Status:"
    puts "   Users: #{User.count} (Officers: #{User.officers.count}, Members: #{User.where(role: 'user').count})"
    puts "   Pending Approvals: #{User.pending.count}"
    puts "   Events: #{Event.count} (Past: #{Event.past.count}, Upcoming: #{Event.upcoming.count})"
    puts "   Attendances: #{Attendance.count}"
    puts "   Demerits: #{Demerit.count}"
    puts "\n✅ Semester transition simulation complete!"
    puts "="*80 + "\n"
  end
  
  desc "Simulate officer turnover only"
  task officer_turnover: :environment do
    super_admin = User.super_admins.first || create_super_admin
    officer_turnover(super_admin)
  end
  
  desc "Archive old events only"
  task archive_events: :environment do
    archive_old_events
  end
  
  desc "Reset attendance history only"
  task reset_attendance: :environment do
    reset_attendance_history
  end
  
  desc "Add new members only"
  task add_members: :environment do
    super_admin = User.super_admins.first || create_super_admin
    manage_members(super_admin)
  end
  
  private
  
  def officer_turnover(super_admin)
    puts "🔄 Simulating officer turnover..."
    
    # Demote 30-50% of current officers back to members
    current_officers = User.officers.where.not(id: super_admin.id)
    
    if current_officers.any?
      officers_to_demote = current_officers.sample((current_officers.count * 0.4).ceil)
      
      officers_to_demote.each do |officer|
        begin
          officer.demote_to_user!(demoted_by: super_admin)
          puts "   ⬇️  Demoted: #{officer.full_name} (#{officer.email}) → Member"
        rescue => e
          puts "   ⚠️  Failed to demote #{officer.email}: #{e.message}"
        end
      end
    else
      puts "   ℹ️  No officers found to demote"
    end
    
    # Promote some regular members to officers
    eligible_members = User.where(role: 'user', approval_status: 'approved')
                          .where.not(id: super_admin.id)
    
    if eligible_members.any?
      new_officers_count = [3, eligible_members.count].min
      members_to_promote = eligible_members.sample(new_officers_count)
      
      members_to_promote.each do |member|
        begin
          member.promote_to_officer!(promoted_by: super_admin)
          puts "   ⬆️  Promoted: #{member.full_name} (#{member.email}) → Officer"
        rescue => e
          puts "   ⚠️  Failed to promote #{member.email}: #{e.message}"
        end
      end
    else
      puts "   ℹ️  No eligible members found to promote"
    end
    
    puts "✅ Officer turnover complete"
  end
  
  def archive_old_events
    puts "🗂️  Archiving old events from previous semester..."
    
    # Define old events as those older than 4 months ago
    cutoff_date = 4.months.ago
    old_events = Event.where('date < ?', cutoff_date)
    
    if old_events.any?
      puts "   Found #{old_events.count} events older than #{cutoff_date.strftime('%Y-%m-%d')}"
      
      # Option 1: Delete old events and their attendances
      deleted_count = 0
      old_events.find_each do |event|
        attendances_count = event.attendances.count
        event.destroy
        deleted_count += 1
        puts "   🗑️  Deleted: #{event.title} (#{event.date.strftime('%Y-%m-%d')}) with #{attendances_count} attendance records"
      end
      
      puts "✅ Archived/deleted #{deleted_count} old events"
    else
      puts "   ℹ️  No old events found to archive"
    end
  end
  
  def reset_attendance_history
    puts "🔄 Resetting attendance history and demerits for new semester..."
    
    # Option 1: Delete ALL attendance records (fresh start)
    attendance_count = Attendance.count
    if attendance_count > 0
      Attendance.destroy_all
      puts "   🗑️  Deleted #{attendance_count} attendance records"
    else
      puts "   ℹ️  No attendance records to delete"
    end
    
    # Option 2: Delete ALL demerits (fresh disciplinary slate)
    demerit_count = Demerit.count
    if demerit_count > 0
      Demerit.destroy_all
      puts "   🗑️  Deleted #{demerit_count} demerit records"
    else
      puts "   ℹ️  No demerit records to delete"
    end
    
    puts "✅ Attendance history and demerits reset"
    
    # Note: If you want to keep historical data, you could add an 'archived' or 'semester' field
    # instead of deleting records
  end
  
  def manage_members(super_admin)
    puts "👥 Managing member transitions..."
    
    # Remove some old members (simulate graduation or leaving)
    # Only remove regular members, not officers or admins
    members = User.where(role: 'user', approval_status: 'approved')
    
    if members.count > 5
      members_to_remove = members.sample([2, (members.count * 0.15).ceil].min)
      
      members_to_remove.each do |member|
        # In a real system, you might want to mark them as 'inactive' instead of deleting
        # For simulation, we'll delete them
        email = member.email
        name = member.full_name
        member.destroy
        puts "   👋 Removed: #{name} (#{email})"
      end
    else
      puts "   ℹ️  Not enough members to simulate removal"
    end
    
    # Add new members (simulate new semester registrations)
    new_members_count = rand(5..10)
    
    puts "\n   Adding #{new_members_count} new members..."
    new_members_count.times do |i|
      member = User.create!(
        email: "new.member#{rand(1000..9999)}@tamu.edu",
        full_name: "New Member #{i + 1}",
        uid: "new_#{SecureRandom.hex(8)}",
        role: 'user',
        approval_status: 'pending'  # New members start as pending
      )
      puts "   ➕ Added: #{member.full_name} (#{member.email}) - Pending Approval"
    end
    
    # Approve some of the pending members
    pending_members = User.pending.sample(rand(2..4))
    pending_members.each do |member|
      begin
        member.approve!(approved_by: super_admin)
        puts "   ✅ Approved: #{member.full_name} (#{member.email})"
      rescue => e
        puts "   ⚠️  Failed to approve #{member.email}: #{e.message}"
      end
    end
    
    puts "✅ Member management complete"
  end
  
  def create_new_semester_events
    puts "📅 Creating events for new semester..."
    
    # Create events for the next 3 months
    start_date = Date.today
    events_created = 0
    
    # Weekly rehearsals (Mondays and Wednesdays, 6:30 PM - 8:30 PM)
    (0..12).each do |week|
      [1, 3].each do |day_of_week| # Monday = 1, Wednesday = 3
        event_date = start_date + week.weeks + (day_of_week - start_date.wday).days
        event_date = event_date + 1.week if event_date < Date.today
        
        next if event_date > (Date.today + 3.months)
        
        event_time = event_date.to_time.change(hour: 18, min: 30)
        end_time = event_time + 2.hours
        
        Event.create!(
          title: "Weekly Rehearsal",
          date: event_time,
          end_time: end_time,
          location: "Rehearsal Hall",
          description: "Regular weekly rehearsal session",
          allow_self_checkin: true
        )
        events_created += 1
      end
    end
    
    # Add some special events
    special_events = [
      { title: "New Member Orientation", weeks_from_now: 0, day: 5, duration: 3 },
      { title: "Fall Performance", weeks_from_now: 6, day: 6, duration: 4 },
      { title: "Community Outreach Event", weeks_from_now: 8, day: 0, duration: 2 },
      { title: "End of Semester Concert", weeks_from_now: 12, day: 6, duration: 5 }
    ]
    
    special_events.each do |event_info|
      event_date = start_date + event_info[:weeks_from_now].weeks + (event_info[:day] - start_date.wday).days
      event_date = event_date + 1.week if event_date < Date.today
      
      next if event_date > (Date.today + 3.months)
      
      event_time = event_date.to_time.change(hour: 19, min: 0)
      end_time = event_time + event_info[:duration].hours
      
      Event.create!(
        title: event_info[:title],
        date: event_time,
        end_time: end_time,
        location: "Performance Hall",
        description: "Special event for the semester",
        allow_self_checkin: false
      )
      events_created += 1
    end
    
    puts "   ✅ Created #{events_created} events for the new semester"
    puts "   📊 Event breakdown:"
    puts "      - Upcoming events: #{Event.upcoming.count}"
    puts "      - Events in next 30 days: #{Event.where(date: Date.today..(Date.today + 30.days)).count}"
    puts "      - Events in next 90 days: #{Event.where(date: Date.today..(Date.today + 90.days)).count}"
    
    puts "✅ New semester events created"
  end
  
  def create_super_admin
    User.create!(
      email: "admin@example.com",
      full_name: "System Admin",
      uid: "admin_#{SecureRandom.hex(8)}",
      role: 'super_admin',
      approval_status: 'approved'
    )
  end
end

