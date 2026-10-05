"""Point the generated native Expo app at the same backend as the web planner."""
import json;
import tomllib;
import from pathlib { Path }

with entry {
    app_path = Path(".jac/mobile-rn/app.json");
    if not app_path.is_file() {
        print("Run jac setup mobile first.");
        raise SystemExit(1);
    }
    config = tomllib.loads(Path("jac.toml").read_text());
    api_url = config["apps"]["mobile"]["client"]["api"]["base_url"];
    app = json.loads(app_path.read_text());
    expo = app["expo"];
    expo["name"] = "Studyline";
    expo["slug"] = "studyline";
    expo.setdefault("extra", {})["apiBaseUrl"] = api_url;
    expo.setdefault("android", {})["package"] = "edu.umich.kokowang.studyline";
    expo.setdefault("ios", {})["bundleIdentifier"] = "edu.umich.kokowang.studyline";
    app_path.write_text(json.dumps(app, indent=2) + "\n");
    print("Native Studyline app configured for " + api_url);
}
