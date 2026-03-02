// app/javascript/controllers/public_calendar_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["calendar"]

  connect() {
    // Check if FullCalendar is already loaded (handles Turbo navigation)
    if (typeof window.FullCalendar === 'undefined') {
      this.loadFullCalendarScript();
    } else {
      this.renderCalendar();
    }
  }

  loadFullCalendarScript() {
    console.log("Downloading FullCalendar...");
    const script = document.createElement("script");
    script.src = "https://cdn.jsdelivr.net/npm/fullcalendar@6.1.10/index.global.min.js";
    script.async = true;
    
    // Once the script finishes downloading, it will trigger the calendar render
    script.onload = () => {
      console.log("FullCalendar loaded successfully!");
      this.renderCalendar();
    };
    
    document.head.appendChild(script);
  }

  renderCalendar() {
    const calendar = new window.FullCalendar.Calendar(this.calendarTarget, {
      initialView: 'dayGridMonth',
      firstDay: 0, // Sunday
      height: 'auto',
      headerToolbar: {
        left: 'prev,next today',
        center: 'title',
        right: 'dayGridMonth,timeGridWeek,timeGridDay'
      },
      // Styling the "EH Look"
      dayHeaderClassNames: 'eh-calendar-header',
      dayCellClassNames: 'eh-calendar-day',
      
      events: '/public/calendar.json',
      eventClick: (info) => {
        info.jsEvent.preventDefault();
        this.showModal(info.event);
      }
    });

    calendar.render();
  }

  showModal(event) {
    document.getElementById('modalTitle').innerText = event.title;
    document.getElementById('modalLocation').innerText = event.extendedProps.location || "TBA";
    document.getElementById('modalDescription').innerText = event.extendedProps.description || "";
    document.getElementById('modalTime').innerText = event.start.toLocaleString();
    
    const ticketBtn = document.getElementById('modalTicketLink');
    if (event.url) {
      ticketBtn.href = event.url;
      ticketBtn.classList.remove('d-none');
    } else {
      ticketBtn.classList.add('d-none');
    }

    const modal = new bootstrap.Modal(document.getElementById('calendarEventModal'));
    modal.show();
  }
}