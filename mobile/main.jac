"""Native mobile screens in mobUI; also previewable via React Native Web."""
import from "@jac/mobui" { View, Text, Pressable, TextInput, ScrollView, StyleSheet, StatusBar, ActivityIndicator, KeyboardAvoidingView, Platform }
import from core.planner { TaskData, Calendar, list_tasks, get_calendar, add_task, set_done }

glob styles = StyleSheet.create({
    "screen": {"flex": 1, "backgroundColor": "#f8f9f3"},
    "body": {"padding": 24, "paddingTop": 54, "paddingBottom": 45, "width": "100%", "maxWidth": 540, "alignSelf": "center"},
    "header": {"flexDirection": "row", "justifyContent": "space-between", "alignItems": "center", "marginBottom": 30},
    "brand": {"fontSize": 23, "fontWeight": "700", "letterSpacing": -0.8, "color": "#244d43"},
    "badge": {"backgroundColor": "#e4eadd", "padding": 10, "borderRadius": 30},
    "badgeText": {"fontSize": 11, "color": "#637752", "fontWeight": "600"},
    "eyebrow": {"fontSize": 10, "letterSpacing": 1.3, "color": "#89927e", "marginBottom": 12},
    "title": {"fontSize": 30, "fontWeight": "700", "letterSpacing": -1, "color": "#304b36"},
    "subtitle": {"fontSize": 12, "lineHeight": 21, "color": "#909a85", "marginTop": 10, "marginBottom": 25},
    "summary": {"backgroundColor": "#eaf0df", "borderRadius": 14, "padding": 22, "marginBottom": 24},
    "summaryNumber": {"fontSize": 31, "fontWeight": "700", "color": "#41603a"},
    "summaryText": {"fontSize": 12, "color": "#819473", "marginTop": 7},
    "row": {"flexDirection": "row", "alignItems": "center", "gap": 9},
    "tabs": {"flexDirection": "row", "gap": 7, "marginBottom": 18},
    "tab": {"paddingVertical": 10, "paddingHorizontal": 15, "borderRadius": 8, "backgroundColor": "#edf0e6"},
    "activeTab": {"backgroundColor": "#244d43"},
    "tabText": {"fontSize": 11, "fontWeight": "600", "color": "#7c8b6c"},
    "activeText": {"color": "white"},
    "task": {"backgroundColor": "white", "borderWidth": 1, "borderColor": "#e6eadf", "borderRadius": 11, "padding": 17, "marginBottom": 10, "flexDirection": "row", "alignItems": "center", "gap": 13},
    "check": {"width": 26, "height": 26, "borderWidth": 1.5, "borderColor": "#cfd9c4", "borderRadius": 8, "alignItems": "center", "justifyContent": "center"},
    "checked": {"backgroundColor": "#87a47a", "borderColor": "#87a47a"},
    "checkText": {"color": "white", "fontWeight": "700"},
    "taskTitle": {"fontSize": 13, "lineHeight": 20, "fontWeight": "600", "color": "#3c4e36"},
    "doneTitle": {"textDecorationLine": "line-through", "color": "#a2ad99"},
    "taskMeta": {"fontSize": 10, "lineHeight": 18, "color": "#8b9b7c", "marginTop": 7},
    "urgent": {"color": "#bd805e"},
    "primary": {"backgroundColor": "#244d43", "padding": 15, "borderRadius": 9, "alignItems": "center", "marginTop": 12},
    "primaryText": {"fontSize": 12, "fontWeight": "600", "color": "white"},
    "secondary": {"padding": 13, "alignItems": "center"},
    "secondaryText": {"fontSize": 11, "color": "#859373"},
    "form": {"padding": 20, "borderRadius": 12, "backgroundColor": "white", "borderWidth": 1, "borderColor": "#e1e7d7", "marginBottom": 22},
    "label": {"fontSize": 10, "fontWeight": "600", "color": "#7f906e", "marginBottom": 7, "marginTop": 14},
    "input": {"borderWidth": 1, "borderColor": "#e2e8db", "borderRadius": 7, "padding": 12, "fontSize": 12, "color": "#495e3d", "backgroundColor": "#fafbf7"},
    "error": {"fontSize": 11, "lineHeight": 19, "color": "#ad7153", "padding": 14, "backgroundColor": "#fbede6", "borderRadius": 8, "marginBottom": 15},
    "empty": {"paddingVertical": 35, "alignItems": "center"},
    "emptyTitle": {"fontSize": 16, "fontWeight": "600", "color": "#7f916e"},
    "footnote": {"textAlign": "center", "fontSize": 10, "lineHeight": 19, "color": "#a0ac91", "marginTop": 24}
});

def:pub app -> JsxElement {
    has tasks: list[TaskData] = [], calendar: Calendar = Calendar(), tab: str = "today",
        loading: bool = True, busy: bool = False, error: str = "", adding: bool = False,
        title: str = "", course: str = "", due: str = "", priority: str = "medium", minutes: str = "30";
    async def refresh {
        try { calendar = await get_calendar(); tasks = await list_tasks(); error = ""; }
        except Exception { error = "Couldn't reach your planner. Check the backend URL and tap Refresh."; }
        loading = False;
    }
    async can with entry { await refresh(); }
    async def toggle(t: TaskData) {
        if busy { return; }
        busy = True;
        try {
            result = await set_done(t.uid, not t.done);
            if result.ok { await refresh(); } else { error = result.error; }
        } except Exception { error = "Couldn't save that change. Try again."; }
        busy = False;
    }
    async def save {
        if busy { return; }
        if not minutes or not minutes.isdigit() { error = "Enter a whole number of minutes."; return; }
        busy = True;
        try {
            result = await add_task(title, course, due, priority, int(minutes));
            if result.ok { title = ""; course = ""; adding = False; tab = "all"; await refresh(); } else { error = result.error; }
        } except Exception { error = "Couldn't add the task. Try again."; }
        busy = False;
    }
    pending = [t for t in tasks if not t.done];
    today = [t for t in pending if t.due and t.due <= calendar.today];
    visible = [t for t in tasks if t.done] if tab == "done" else (today if tab == "today" else pending);
    return <KeyboardAvoidingView style={styles.screen} behavior={"padding" if Platform.OS == "ios" else "height"}>
        <StatusBar barStyle="dark-content" backgroundColor="#f8f9f3"/>
        <ScrollView contentContainerStyle={styles.body} keyboardShouldPersistTaps="handled">
            <View style={styles.header}><Text style={styles.brand}>studyline.</Text><View style={styles.badge}><Text style={styles.badgeText}>XW</Text></View></View>
            <Text style={styles.eyebrow}>{calendar.heading.upper() or "YOUR LITTLE SPACE"}</Text>
            <Text style={styles.title}>One step at a time.</Text><Text style={styles.subtitle}>Your plans, wherever the day takes you.</Text>
            <View style={styles.summary}><Text style={styles.summaryNumber}>{len(today)} tasks</Text><Text style={styles.summaryText}>due today or overdue · {sum([t.minutes for t in today])} min estimated</Text></View>
            {if error { <Text style={styles.error} accessibilityRole="alert">{error}</Text> }}
            <View style={styles.tabs}>{[
                <Pressable key={key} style={[styles.tab, styles.activeTab if tab == key else None]} onPress={lambda { tab = key; }} accessibilityRole="button" accessibilityLabel={label}><Text style={[styles.tabText, styles.activeText if tab == key else None]}>{label}</Text></Pressable> for (key, label) in [("today", "Today"), ("all", "All tasks"), ("done", "Done")]
            ]}</View>
            {if adding {
                <View style={styles.form}><Text style={styles.taskTitle}>What's on your mind?</Text>
                    <Text style={styles.label}>TASK</Text><TextInput style={styles.input} placeholder="Finish problem set 3" accessibilityLabel="Task title" value={title} onChangeText={lambda (v: str) { title = v; }} maxLength={160}/>
                    <Text style={styles.label}>COURSE OR AREA</Text><TextInput style={styles.input} placeholder="EECS 449 or Personal" accessibilityLabel="Course" value={course} onChangeText={lambda (v: str) { course = v; }} maxLength={40}/>
                    <Text style={styles.label}>DEADLINE · YYYY-MM-DD OR BLANK</Text><TextInput style={styles.input} placeholder="YYYY-MM-DD" accessibilityLabel="Deadline" value={due} onChangeText={lambda (v: str) { due = v; }} autoCapitalize="none"/>
                    <Text style={styles.label}>ESTIMATED MINUTES</Text><TextInput style={styles.input} accessibilityLabel="Estimated minutes" value={minutes} onChangeText={lambda (v: str) { minutes = v; }} keyboardType="number-pad"/>
                    <Text style={styles.label}>PRIORITY</Text><View style={styles.row}>{[
                        <Pressable key={p} style={[styles.tab, styles.activeTab if priority == p else None]} accessibilityRole="button" accessibilityLabel={p + " priority"} onPress={lambda { priority = p; }}><Text style={[styles.tabText, styles.activeText if priority == p else None]}>{p.capitalize()}</Text></Pressable> for p in ["low", "medium", "high"]
                    ]}</View>
                    <Pressable style={styles.primary} disabled={busy} accessibilityRole="button" onPress={save}><Text style={styles.primaryText}>{"Saving..." if busy else "Add task"}</Text></Pressable>
                    <Pressable style={styles.secondary} disabled={busy} onPress={lambda { adding = False; error = ""; }} accessibilityRole="button"><Text style={styles.secondaryText}>Cancel</Text></Pressable>
                </View>
            }}
            {if loading { <ActivityIndicator color="#244d43" size="large"/> } elif not visible {
                <View style={styles.empty}><Text style={styles.emptyTitle}>A little breathing room.</Text><Text style={styles.subtitle}>No tasks in this view.</Text></View>
            } else { <View>{[
                <View key={t.uid} style={styles.task}><Pressable accessibilityRole="button" accessibilityLabel={("Reopen " if t.done else "Complete ") + t.title} disabled={busy} style={[styles.check, styles.checked if t.done else None]} onPress={lambda { toggle(t); }}><Text style={styles.checkText}>{"✓" if t.done else ""}</Text></Pressable><View style={{"flex": 1}}><Text style={[styles.taskTitle, styles.doneTitle if t.done else None]}>{t.title}</Text><Text style={[styles.taskMeta, styles.urgent if t.due and t.due <= calendar.today and not t.done else None]}>{t.course + " · " + ("Today" if t.due == calendar.today else (t.due or "No deadline")) + " · " + str(t.minutes) + " min · " + t.priority}</Text></View></View> for t in visible
            ]}</View> }}
            {if not adding { <Pressable style={styles.primary} accessibilityRole="button" onPress={lambda { due = calendar.today; error = ""; adding = True; }}><Text style={styles.primaryText}>＋ New task</Text></Pressable> }}
            <Pressable style={styles.secondary} accessibilityRole="button" onPress={refresh}><Text style={styles.secondaryText}>Refresh tasks</Text></Pressable>
            <Text style={styles.footnote}>The same tasks as your web and terminal planner.{"\n"}Small steps. A little more clarity.</Text>
        </ScrollView>
    </KeyboardAvoidingView>;
}
