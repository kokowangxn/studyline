"""Exercise the real Jac API and CLI; clean up only the task this test creates."""
import argparse
import json
import shutil
import subprocess
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--url', default='http://127.0.0.1:8000')
    parser.add_argument('--jac', default=shutil.which('jac') or str(ROOT / '.tools' / 'jac'))
    args = parser.parse_args()
    jac = str(Path(args.jac).resolve())

    def api(name, **data):
        request = urllib.request.Request(
            args.url.rstrip('/') + '/api/planner/function/' + name,
            data=json.dumps(data).encode(),
            headers={'Content-Type': 'application/json'},
        )
        response = json.load(urllib.request.urlopen(request, timeout=20))
        assert response['ok'], response
        return response['data']['result']

    def cli(*words):
        result = subprocess.run(
            [jac, 'run', 'cli', '--server', args.url, '--json', *words],
            cwd=ROOT, capture_output=True, text=True, timeout=40,
        )
        assert result.returncode == 0, result.stderr or result.stdout
        return result.stdout

    uid = None
    initial_ids = {t['uid'] for t in api('list_tasks')}
    try:
        for invalid in [
            {'title': '   '},
            {'title': 'Invalid date', 'due': '2026-02-30'},
            {'title': 'Invalid format', 'due': '20261005'},
            {'title': 'Invalid priority', 'priority': 'urgent'},
            {'title': 'Invalid effort', 'minutes': 0},
            {'title': 'Too long', 'notes': 'x' * 1001},
        ]:
            assert api('add_task', **invalid)['ok'] is False
        assert {t['uid'] for t in api('list_tasks')} == initial_ids
        print('PASS server validation rejects bad data without creating tasks')

        today = api('get_calendar')['today']
        created = json.loads(cli('add', 'Studyline smoke test', '--course', 'TEST', '--due', today, '--priority', 'high', '--minutes', '25'))[0]
        uid = created['id']
        assert any(t['uid'] == uid for t in api('list_tasks'))
        assert any(t['id'] == uid for t in json.loads(cli('today')))
        print('PASS CLI creates a task visible through the shared API and Today view')

        assert api('update_task', uid=uid, title='Updated smoke test', course='TEST', due=today, priority='low', minutes=35, notes='Shared across interfaces')['ok']
        edited = next(t for t in json.loads(cli('list')) if t['id'] == uid)
        assert edited['title'] == 'Updated smoke test' and edited['minutes'] == 35
        print('PASS edits made through the API are visible in the CLI')

        cli('done', uid)
        assert api('set_done', uid=uid, done=True)['task']['done'] is True
        assert any(t['id'] == uid for t in json.loads(cli('completed')))
        assert not any(t['id'] == uid for t in json.loads(cli('today')))
        cli('reopen', uid)
        assert api('set_done', uid=uid, done=False)['task']['done'] is False
        print('PASS completion is idempotent and reopening restores the task')

        assert not api('set_done', uid='missing-task', done=True)['ok']
        assert not api('delete_task', uid='missing-task')['ok']
        assert not api('load_demo')['ok']
        cli('delete', uid, '--yes')
        assert not any(t['uid'] == uid for t in api('list_tasks'))
        uid = None
        assert {t['uid'] for t in api('list_tasks')} == initial_ids
        print('PASS deletion, missing IDs, and demo protection; existing tasks preserved')
        print('All integration checks passed.')
    finally:
        if uid:
            api('delete_task', uid=uid)


if __name__ == '__main__':
    main()
