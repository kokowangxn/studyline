import from core.planner { TaskData, Calendar, list_tasks, add_task, update_task, set_done, delete_task, load_demo, get_calendar }
import from react { useEffect }
import from "lucide-react" { BookOpen, LayoutDashboard, CalendarDays, ListTodo, CheckCheck, Plus, ArrowUpRight, Clock3, Search, SlidersHorizontal, ChevronRight, X, Pencil, Trash2, RefreshCw, Terminal, Smartphone, Check, Sprout, ArrowRight }
import "./styles.css";

def:pub app -> JsxElement {
    has tasks: list[TaskData] = [],
        calendar: Calendar = Calendar(),
        view: str = "week",
        course_filter: str = "All courses",
        query: str = "",
        selected_day: str = "",
        loading: bool = True,
        busy: bool = False,
        error: str = "",
        modal: bool = False,
        edit_id: str = "",
        title: str = "",
        course: str = "",
        due: str = "",
        priority: str = "medium",
        minutes: str = "30",
        notes: str = "",
        form_error: str = "";

    async def refresh {
        try {
            calendar = await get_calendar();
            tasks = await list_tasks();
            error = "";
        } except Exception {
            error = "Couldn't reach the planner. Check that the server is running, then refresh.";
        }
        loading = False;
    }
    async can with entry { await refresh(); }
    useEffect(lambda {
        timer = setInterval(lambda { refresh(); }, 15000);
        return lambda { clearInterval(timer); };
    }, []);

    def navigate(next_view: str) {
        view = next_view;
        selected_day = "";
    }
    def open_new {
        edit_id = ""; title = ""; course = ""; due = selected_day or calendar.today;
        priority = "medium"; minutes = "30"; notes = ""; form_error = ""; modal = True;
    }
    def open_edit(t: TaskData | None) {
        if t is None { return; }
        edit_id = t.uid; title = t.title; course = t.course; due = t.due;
        priority = t.priority; minutes = str(t.minutes); notes = t.notes; form_error = ""; modal = True;
    }
    async def save(e: FormEvent) {
        e.preventDefault();
        if busy { return; }
        if not minutes or not minutes.isdigit() { form_error = "Enter a whole number of minutes."; return; }
        busy = True;
        try {
            result = await update_task(edit_id, title, course, due, priority, int(minutes), notes) if edit_id else await add_task(title, course, due, priority, int(minutes), notes);
            if result.ok { modal = False; await refresh(); } else { form_error = result.error; }
        } except Exception { form_error = "Couldn't save your task. Please try again."; }
        busy = False;
    }
    async def toggle(t: TaskData) {
        if busy { return; }
        busy = True;
        try {
            result = await set_done(t.uid, not t.done);
            if not result.ok { error = result.error; } else { await refresh(); }
        } except Exception { error = "Couldn't update this task. Please try again."; }
        busy = False;
    }
    async def remove(t: TaskData) {
        if not window.confirm("Delete “" + t.title + "”? This cannot be undone.") { return; }
        busy = True;
        try {
            result = await delete_task(t.uid);
            if result.ok { await refresh(); } else { error = result.error; }
        } except Exception { error = "Couldn't delete this task. Please try again."; }
        busy = False;
    }
    async def demo {
        busy = True;
        try {
            result = await load_demo();
            if result.ok { await refresh(); } else { error = result.error; }
        } except Exception { error = "Couldn't load sample tasks. Please try again."; }
        busy = False;
    }
    def due_label(t: TaskData) -> str {
        if not t.due { return "No deadline"; }
        if t.due == calendar.today { return "Today"; }
        if t.due < calendar.today and not t.done { return "Overdue · " + t.due[5:]; }
        return t.due[5:].replace("-", "/");
    }

    open_tasks = [t for t in tasks if not t.done];
    done_tasks = [t for t in tasks if t.done];
    today_tasks = [t for t in open_tasks if t.due and t.due <= calendar.today];
    week_tasks = [t for t in open_tasks if t.due and t.due <= calendar.week_end];
    week_minutes = sum([t.minutes for t in week_tasks]);
    courses: list[str] = [];
    for t in tasks { if t.course not in courses { courses.append(t.course); } }
    courses = sorted(courses);
    visible = done_tasks if view == "completed" else (today_tasks if view == "today" else (week_tasks if view == "week" else open_tasks));
    if selected_day { visible = [t for t in visible if t.due == selected_day]; }
    if course_filter != "All courses" { visible = [t for t in visible if t.course == course_filter]; }
    if query { visible = [t for t in visible if query.lower() in (t.title + " " + t.course + " " + t.notes).lower()]; }
    next_task = week_tasks[0] if week_tasks else (open_tasks[0] if open_tasks else None);
    headings = {"today": "Today's plan", "week": "Your week, at a glance", "all": "All your tasks", "completed": "Look how far you've come"};
    labels = {"today": "Today", "week": "This week", "all": "All tasks", "completed": "Completed"};

    return <div className="app-shell">
        <aside className="sidebar">
            <a className="brand" href="/"><span className="brand-mark"><BookOpen size={23}/></span>studyline<span className="brand-dot">.</span></a>
            <div className="workspace-label">YOUR LITTLE SPACE</div>
            <nav aria-label="Planner views">
                <button className={"nav-item " + ("active" if view == "week" else "")} onClick={lambda { navigate("week"); }}><LayoutDashboard size={19}/>Overview</button>
                <button className={"nav-item " + ("active" if view == "today" else "")} onClick={lambda { navigate("today"); }}><CalendarDays size={19}/>Today<span className="nav-count">{len(today_tasks)}</span></button>
                <button className={"nav-item " + ("active" if view == "all" else "")} onClick={lambda { navigate("all"); }}><ListTodo size={19}/>All tasks<span className="nav-count">{len(open_tasks)}</span></button>
                <button className={"nav-item " + ("active" if view == "completed" else "")} onClick={lambda { navigate("completed"); }}><CheckCheck size={19}/>Completed</button>
            </nav>
            <div className="course-heading">COURSES<span>{len(courses)}</span></div>
            <button className={"course-link " + ("chosen" if course_filter == "All courses" else "")} onClick={lambda { course_filter = "All courses"; }}>All courses</button>
            {[
                <button key={c} className={"course-link " + ("chosen" if course_filter == c else "")} onClick={lambda { course_filter = c; }}><span className="course-dot"/>{c}</button> for c in courses
            ]}
            <div className="sidebar-bottom">
                <div className="small-note"><Sprout size={23}/><p>Small steps.<br/><strong>A little more clarity.</strong></p></div>
                <div className="profile"><span className="avatar">XW</span><div><strong>Xinning Wang</strong><small>Personal workspace</small></div></div>
            </div>
        </aside>
        <div className="main-shell">
            <header className="topbar"><span>My workspace <ChevronRight size={14}/><strong>{labels[view]}</strong></span><span className="sync-label"><span className="tiny-dot"/>Saved across your devices<button className="icon-button" onClick={refresh} title="Refresh tasks" aria-label="Refresh tasks"><RefreshCw size={15}/></button></span></header>
            <main>
                <div className="page-heading"><div><div className="eyebrow">{calendar.heading or "YOUR PERSONAL PLANNER"}</div><h1>{headings[view]}<span className="heading-dot">.</span></h1><p>A little planning. A little breathing room. You've got this.</p></div><button className="primary" onClick={open_new}><Plus size={18}/>New task</button></div>
                {if error { <div className="error-banner" role="alert">{error}<button onClick={refresh}>Try again</button></div> }}
                <section className="stats" aria-label="Planning summary">
                    <div className="stat"><span className="stat-icon peach"><CalendarDays size={20}/></span><div><span>Due today & overdue</span><strong>{len(today_tasks)}<small>tasks to keep in view</small></strong></div></div>
                    <div className="stat"><span className="stat-icon lavender"><ListTodo size={20}/></span><div><span>Next 7 days</span><strong>{len(week_tasks)}<small>one step at a time</small></strong></div></div>
                    <div className="stat"><span className="stat-icon mint"><CheckCheck size={20}/></span><div><span>Completed</span><strong>{len(done_tasks)}<small>little wins, adding up</small></strong></div></div>
                </section>
                <div className="content-grid">
                    <div className="primary-column">
                        <section className="week-panel"><div className="section-heading"><h2>The next seven days</h2><span>{calendar.days[0].iso[5:] + " — " + calendar.week_end[5:] if calendar.days else ""}</span></div><div className="week-strip">{[
                            <button key={d.iso} className={"day " + ("selected" if selected_day == d.iso else ("current" if d.iso == calendar.today else ""))} onClick={lambda { view = "week"; selected_day = "" if selected_day == d.iso else d.iso; }} aria-label={"Tasks due " + d.iso}><span>{d.label}</span><strong>{d.number}</strong><span className="day-indicator">{len([t for t in open_tasks if t.due == d.iso]) or "·"}</span></button> for d in calendar.days
                        ]}</div></section>
                        <section className="task-panel"><div className="section-heading"><h2>{"Tasks for " + selected_day if selected_day else labels[view]}<span className="count-badge">{len(visible)}</span></h2><button className="text-button" onClick={lambda { navigate("all"); course_filter = "All courses"; query = ""; }}>View all<ArrowUpRight size={15}/></button></div>
                            <div className="filters"><div className="search-field"><Search size={17}/><input aria-label="Search tasks" placeholder="Find a task..." value={query} onChange={lambda (e: ChangeEvent) { query = e.target.value; }}/></div><div className="course-select"><SlidersHorizontal size={15}/><select aria-label="Filter by course" value={course_filter} onChange={lambda (e: ChangeEvent) { course_filter = e.target.value; }}><option>All courses</option>{[<option key={c}>{c}</option> for c in courses]}</select></div></div>
                            {if loading { <div className="empty-state"><RefreshCw size={27}/><h3>Getting your plans ready...</h3></div> } elif not visible {
                                <div className="empty-state"><span className="empty-icon"><Sprout size={30}/></span><h3>{"A fresh page for your plans" if not tasks else "A little breathing room"}</h3><p>{"Add your first task, or explore a sample week." if not tasks else "No tasks in this view. Try another day or filter."}</p>{if not tasks { <div className="empty-actions"><button className="primary" onClick={open_new}><Plus size={16}/>Add a task</button><button className="secondary" disabled={busy} onClick={demo}>Explore sample week</button></div> }}</div>
                            } else { <div className="task-list">{[
                                <article key={t.uid} className={"task-row " + ("is-done" if t.done else "")}>
                                    <button className={"check-button " + ("checked" if t.done else "")} disabled={busy} aria-label={("Reopen " if t.done else "Complete ") + t.title} onClick={lambda { toggle(t); }}>{if t.done { <Check size={14}/> }}</button>
                                    <button className="task-content" onClick={lambda { open_edit(t); }}><strong>{t.title}</strong><span><span className="course-pill">{t.course}</span><span className={"due-text " + ("urgent" if t.due and t.due <= calendar.today and not t.done else "")}><CalendarDays size={12}/>{due_label(t)}</span><span className="duration"><Clock3 size={12}/>{t.minutes} min</span></span></button>
                                    <span className={"priority " + t.priority}><span className="tiny-dot"/>{t.priority.capitalize()}</span>
                                    <div className="row-actions"><button className="icon-button" title="Edit task" aria-label={"Edit " + t.title} onClick={lambda { open_edit(t); }}><Pencil size={15}/></button><button className="icon-button danger" title="Delete task" disabled={busy} aria-label={"Delete " + t.title} onClick={lambda { remove(t); }}><Trash2 size={15}/></button></div>
                                </article> for t in visible
                            ]}</div> }}
                            <div className="task-footer"><span>{sum([t.minutes for t in visible])} minutes estimated in this view</span><span>Make room for breaks, too.</span></div>
                        </section>
                    </div>
                    <aside className="right-column">
                        <section className="next-card"><div className="next-label"><span className="spark">✳</span>ONE SMALL NEXT STEP</div><h2>{next_task.title if next_task else "Start wherever you are."}</h2><p>{next_task.notes or "Give this one your attention. The rest can wait a little." if next_task else "A task written down is a little less to carry around."}</p>{if next_task { <div className="next-meta"><span>{next_task.course}</span><span><Clock3 size={13}/>{next_task.minutes} min</span></div><button onClick={lambda { open_edit(next_task); }}>Open this task<ArrowRight size={17}/></button> } else { <button onClick={open_new}>Write down a task<ArrowRight size={17}/></button> }}</section>
                        <section className="workload-card"><div className="section-heading"><h2>A manageable week</h2><Clock3 size={17}/></div><div className="workload-number">{round(week_minutes / 60, 1)}<span>hrs planned</span></div><p>Estimated effort for your upcoming deadlines.</p><div className="workload-courses">{[
                            <div key={c}><div><span><span className="tiny-dot"/>{c}</span><strong>{sum([t.minutes for t in week_tasks if t.course == c])}m</strong></div><div className="meter"><span style={{"width": str(min(100.0, sum([t.minutes for t in week_tasks if t.course == c]) * 100 / max(1, week_minutes))) + "%"}}/></div></div> for c in courses if any([t.course == c for t in week_tasks])
                        ]}</div>{if not week_tasks { <small>New deadlines will appear here.</small> }}</section>
                        <div className="everywhere-note"><div><Smartphone size={17}/><Terminal size={17}/></div><strong>Your plans go with you.</strong><p>On your desk, on your phone,<br/>or one quick terminal command away.</p></div>
                    </aside>
                </div>
                <footer className="page-footer"><span>Less in your head. More in your day.</span><span>Made with Jac <span className="footer-dot">·</span> Studyline</span></footer>
            </main>
        </div>
        {if modal {
            <div className="modal-backdrop" onClick={lambda (e: MouseEvent) { if e.target == e.currentTarget and not busy { modal = False; } }}>
                <section className="modal" role="dialog" aria-modal="true" aria-labelledby="task-dialog-title" onKeyDown={lambda (e: KeyboardEvent) { if e.key == "Escape" and not busy { modal = False; } }}><div className="modal-heading"><div><span className="eyebrow">MAKE A LITTLE ROOM</span><h2 id="task-dialog-title">{"Edit your task" if edit_id else "What's on your mind?"}</h2></div><button className="icon-button" aria-label="Close task form" disabled={busy} onClick={lambda { modal = False; }}><X size={21}/></button></div>
                    <form onSubmit={save}>
                        <label>Task<input autoFocus required maxLength={160} placeholder="e.g. Finish problem set 3" value={title} onChange={lambda (e: ChangeEvent) { title = e.target.value; }}/></label>
                        <div className="form-grid"><label>Course or area<input maxLength={40} placeholder="e.g. EECS 449" value={course} onChange={lambda (e: ChangeEvent) { course = e.target.value; }}/></label><label>Deadline<input type="date" value={due} onChange={lambda (e: ChangeEvent) { due = e.target.value; }}/></label></div>
                        <div className="form-grid"><label>Priority<select value={priority} onChange={lambda (e: ChangeEvent) { priority = e.target.value; }}><option value="low">Low · when there's room</option><option value="medium">Medium · keep it moving</option><option value="high">High · give it attention</option></select></label><label>Estimated time (minutes)<input type="number" min="5" max="480" step="1" required value={minutes} onChange={lambda (e: ChangeEvent) { minutes = e.target.value; }}/></label></div>
                        <label>Notes <span className="optional">optional</span><textarea rows={3} maxLength={1000} placeholder="The first step, a useful link, a little reminder..." value={notes} onChange={lambda (e: ChangeEvent) { notes = e.target.value; }}/></label>
                        {if form_error { <p className="form-error" role="alert">{form_error}</p> }}
                        <div className="modal-footer"><button type="button" className="secondary" disabled={busy} onClick={lambda { modal = False; }}>Cancel</button><button type="submit" className="primary" disabled={busy}>{"Saving..." if busy else ("Save changes" if edit_id else "Add task")}<ArrowRight size={16}/></button></div>
                    </form>
                </section>
            </div>
        }}
    </div>;
}
