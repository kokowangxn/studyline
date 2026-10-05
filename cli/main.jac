"""A terminal client of the running planner, never a separate task database."""
import argparse;
import asyncio;
import json;
import os;
import sys;
import from jaclang.server.bridge { BridgeError }
import from core.planner { TaskData, Mutation, list_tasks, get_calendar, add_task, set_done, delete_task, load_demo }

# Accept dictionary payloads and hydrated Jac objects at the transport boundary.
# Planning rules remain on the server.
def decode_task(raw: any) -> TaskData {
    if isinstance(raw, dict) {
        return TaskData(uid=raw["uid"], title=raw["title"], course=raw["course"], due=raw["due"], priority=raw["priority"], minutes=raw["minutes"], notes=raw["notes"], done=raw["done"]);
    }
    return raw;
}

async def fetch_tasks -> list[TaskData] {
    raw: any = await list_tasks();
    return [decode_task(t) for t in raw];
}

def decode_result(raw: any) -> Mutation {
    if isinstance(raw, dict) {
        return Mutation(ok=raw["ok"], error=raw["error"], task=decode_task(raw["task"]) if raw.get("task") else None);
    }
    return raw;
}

def parser -> argparse.ArgumentParser {
    p = argparse.ArgumentParser(prog="jac run cli", description="Studyline: your coursework planner in the terminal.");
    p.add_argument("--server", `default=os.environ.get("STUDYLINE_URL", "http://127.0.0.1:8000"), help="Backend URL (or set STUDYLINE_URL)");
    p.add_argument("--json", action="store_true", help="Print machine-readable task JSON");
    commands = p.add_subparsers(dest="command", required=True);
    for name in ["today", "week", "list", "completed"] { commands.add_parser(name, help="Show " + name + " tasks"); }
    add = commands.add_parser("add", help="Quickly add a task");
    add.add_argument("title");
    add.add_argument("--course", `default="Personal");
    add.add_argument("--due", `default="", help="YYYY-MM-DD, or omit for no deadline");
    add.add_argument("--priority", choices=["low", "medium", "high"], `default="medium");
    add.add_argument("--minutes", `type=int, `default=30);
    add.add_argument("--notes", `default="");
    for name in ["done", "reopen", "delete"] {
        command = commands.add_parser(name, help=name.capitalize() + " a task by ID");
        command.add_argument("id", help="Full ID or a unique prefix shown by list");
        if name == "delete" { command.add_argument("--yes", action="store_true", help="Skip deletion confirmation"); }
    }
    commands.add_parser("demo", help="Load a sample week into an empty planner");
    return p;
}

def task_dict(t: TaskData) -> dict[str, any] {
    return {"id": t.uid, "title": t.title, "course": t.course, "due": t.due, "priority": t.priority, "minutes": t.minutes, "notes": t.notes, "done": t.done};
}

def print_tasks(tasks: list[TaskData], as_json: bool) {
    if as_json { print(json.dumps([task_dict(t) for t in tasks], indent=2)); return; }
    if not tasks { print("A little breathing room. No tasks in this view."); return; }
    for t in tasks {
        print(("[x] " if t.done else "[ ] ") + t.uid + "  " + t.title);
        print("    " + t.course + " · " + (t.due or "no deadline") + " · " + t.priority + " · " + str(t.minutes) + " min");
    }
    print("\n" + str(len(tasks)) + " task(s) · " + str(sum([t.minutes for t in tasks])) + " minutes estimated");
}

async def main(argv: list[str]) -> int {
    args = parser().parse_args(argv);
    os.environ["JAC_APP_PLANNER_URL"] = args.server.rstrip("/");
    os.environ["JAC_APP_PLANNER_ROUTE"] = "/api/planner";
    try {
        if args.command in ["list", "today", "week", "completed"] {
            tasks = await fetch_tasks();
            if args.command == "completed" { tasks = [t for t in tasks if t.done]; }
            else { tasks = [t for t in tasks if not t.done]; }
            if args.command in ["today", "week"] {
                calendar: any = await get_calendar();
                if isinstance(calendar, dict) { end = calendar["today"] if args.command == "today" else calendar["week_end"]; }
                else { end = calendar.today if args.command == "today" else calendar.week_end; }
                tasks = [t for t in tasks if t.due and t.due <= end];
            }
            print_tasks(tasks, args.json);
            return 0;
        }
        result = Mutation();
        if args.command == "add" {
            result = await add_task(args.title, args.course, args.due, args.priority, args.minutes, args.notes);
        } elif args.command == "demo" { result = await load_demo(); }
        else {
            matches = [t for t in await fetch_tasks() if t.uid.startswith(args.id)];
            if len(matches) != 1 {
                print("No unique task matches that ID. Run 'jac run cli list' and use the full ID.", file=sys.stderr);
                return 2;
            }
            task = matches[0];
            if args.command == "delete" {
                if not args.yes and input("Delete “" + task.title + "”? [y/N] ").lower() != "y" { print("Cancelled."); return 0; }
                result = await delete_task(task.uid);
            } else { result = await set_done(task.uid, args.command == "done"); }
        }
        result = decode_result(result);
        if not result.ok { print(result.error, file=sys.stderr); return 2; }
        if result.task is not None { print_tasks([result.task], args.json); }
        else { print("Sample week added." if args.command == "demo" else "Task deleted."); }
        return 0;
    } except BridgeError as e {
        print("Couldn't reach the planner at " + args.server + ". Start it with 'jac run'.\n" + str(e), file=sys.stderr);
        return 1;
    } except KeyboardInterrupt { return 130; }
}

with entry:__main__ { sys.`exit(asyncio.run(main(sys.argv[1:]))); }
