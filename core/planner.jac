"""Studyline's single source of planning data; public for local, personal use."""
import uuid;

import from datetime { date, timedelta }

obj TaskData {
    has uid: str = "",
        title: str = "",
        course: str = "Personal",
        due: str = "",
        priority: str = "medium",
        minutes: int = 30,
        notes: str = "",
        done: bool = False;
}

obj Mutation {
    has ok: bool = False,
        error: str = "",
        task: TaskData | None = None;
}

obj Day {
    has iso: str = "",
        label: str = "",
        number: str = "";
}

obj Calendar {
    has today: str = "",
        week_end: str = "",
        heading: str = "",
        days: list[Day] = [];
}


node Task {
    has uid: str = "",
        title: str = "",
        course: str = "Personal",
        due: str = "",
        priority: str = "medium",
        minutes: int = 30,
        notes: str = "",
        done: bool = False;
}

def:priv _view(t: Task) -> TaskData {
    return TaskData(uid=t.uid, title=t.title, course=t.course, due=t.due, priority=t.priority, minutes=t.minutes, notes=t.notes, done=t.done);
}

# Validation is shared by create and edit, so every interface gets the same rules.
def:priv validate(title: str, course: str, due: str, priority: str, minutes: int, notes: str) -> str {
    if not title.strip() or len(title.strip()) > 160 {
        return "Give the task a title between 1 and 160 characters.";
    }
    if len(course.strip()) > 40 { return "Course names can be at most 40 characters."; }
    if priority not in ["high", "medium", "low"] { return "Choose high, medium, or low priority."; }
    if minutes < 5 or minutes > 480 { return "Estimated time must be between 5 and 480 minutes."; }
    if len(notes) > 1000 { return "Notes can be at most 1,000 characters."; }
    if due {
        try {
            parsed = date.fromisoformat(due);
            if parsed.isoformat() != due { return "Use a date in YYYY-MM-DD format."; }
        } except ValueError { return "Use a valid date in YYYY-MM-DD format."; }
    }
    return "";
}

def:pub list_tasks -> list[TaskData] {
    tasks = [_view(t) for t in [root-->][?:Task]];
    ranks = {"high": 0, "medium": 1, "low": 2};
    return sorted(tasks, key=lambda (t: TaskData) { return (t.done, t.due or "9999-12-31", ranks[t.priority], t.title); });
}

def:pub add_task(title: str, course: str = "Personal", due: str = "", priority: str = "medium", minutes: int = 30, notes: str = "") -> Mutation {
    error = validate(title, course, due, priority, minutes, notes);
    if error { return Mutation(error=error); }
    task = Task(uid=uuid.uuid4().hex[:12], title=title.strip(), course=course.strip() or "Personal", due=due, priority=priority, minutes=minutes, notes=notes.strip());
    root ++> task;
    return Mutation(ok=True, task=_view(task));
}

def:pub update_task(uid: str, title: str, course: str, due: str, priority: str, minutes: int, notes: str = "") -> Mutation {
    error = validate(title, course, due, priority, minutes, notes);
    if error { return Mutation(error=error); }
    for task in [root-->][?:Task] {
        if task.uid == uid {
            task.title = title.strip();
            task.course = course.strip() or "Personal";
            task.due = due;
            task.priority = priority;
            task.minutes = minutes;
            task.notes = notes.strip();
            return Mutation(ok=True, task=_view(task));
        }
    }
    return Mutation(error="Task not found. Refresh your list and try again.");
}

# Explicit done state makes repeat calls safe, including mobile double taps.
def:pub set_done(uid: str, done: bool) -> Mutation {
    for task in [root-->][?:Task] {
        if task.uid == uid {
            task.done = done;
            return Mutation(ok=True, task=_view(task));
        }
    }
    return Mutation(error="Task not found. Refresh your list and try again.");
}

def:pub delete_task(uid: str) -> Mutation {
    for task in [root-->][?:Task] {
        if task.uid == uid {
            del task;
            return Mutation(ok=True);
        }
    }
    return Mutation(error="Task not found. Refresh your list and try again.");
}

# Demo is an explicit action and never overwrites someone's existing planner.
def:pub load_demo -> Mutation {
    if [root-->][?:Task] { return Mutation(error="Sample tasks can only be added to an empty planner."); }
    today = date.today();
    examples = [
        ("Finish personal planner", "EECS 449", 0, "high", 90, "Check the web, mobile, and CLI workflows before submitting."),
        ("Review lecture notes", "EECS 445", 0, "medium", 30, "Focus on the examples from the last lecture."),
        ("Read chapter 4", "STATS 412", 1, "low", 45, ""),
        ("Work through problem set", "MATH 214", 2, "high", 60, "Start with the questions that need office hours."),
        ("Outline project report", "EECS 449", 4, "medium", 45, ""),
        ("Plan next week's meals", "Personal", 6, "low", 20, ""),
        ("Set up Jac workspace", "EECS 449", 0, "medium", 15, "")
    ];
    for (title, course, offset, priority, minutes, notes) in examples {
        task = Task(uid=uuid.uuid4().hex[:12], title=title, course=course, due=(today + timedelta(days=offset)).isoformat(), priority=priority, minutes=minutes, notes=notes, done=title == "Set up Jac workspace");
        root ++> task;
    }
    return Mutation(ok=True);
}

def:pub get_calendar -> Calendar {
    today = date.today();
    return Calendar(today=today.isoformat(), week_end=(today + timedelta(days=6)).isoformat(), heading=today.strftime("%A, %B %d"), days=[Day(iso=(today + timedelta(days=i)).isoformat(), label=(today + timedelta(days=i)).strftime("%a"), number=str((today + timedelta(days=i)).day)) for i in range(7)]);
}
