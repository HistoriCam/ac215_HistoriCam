import requests, time, csv, sys
from datetime import datetime

S = requests.Session()
S.headers.update({
    'User-Agent': 'HistoriCam/1.0 (Educational project; contact: hughvandeventer@g.harvard.edu'
})
API = "https://en.wikipedia.org/w/api.php"
CAT_TITLE = "Category:Harvard_University_buildings"

def list_category_members(category):
    # returns pageids and titles
    cmcontinue = None
    pages = []
    while True:
        params = {
            "action": "query",
            "format": "json",
            "list": "categorymembers",
            "cmtitle": category,
            "cmlimit": "500"
        }
        if cmcontinue:
            params["cmcontinue"] = cmcontinue
        r = S.get(API, params=params, timeout=30)
        r.raise_for_status()
        data = r.json()
        pages.extend(data["query"]["categorymembers"])
        cmcontinue = data.get("continue", {}).get("cmcontinue")
        if not cmcontinue:
            break
    return pages

def fetch_page_details(pageids):
    # batch in chunks to fetch coords + pageprops (QID)
    details = {}
    for i in range(0, len(pageids), 50):
        chunk = pageids[i:i+50]
        params = {
            "action": "query",
            "format": "json",
            "prop": "coordinates|pageprops",
            "pageids": "|".join(str(pid) for pid in chunk),
            "coprop": "type|dim|name|country|region|globe",
            "ppprop": "wikibase_item"
        }
        r = S.get(API, params=params, timeout=30)
        r.raise_for_status()
        for pid, page in r.json()["query"]["pages"].items():
            coords = page.get("coordinates", [{}])[0]
            details[int(pid)] = {
                "title": page["title"],
                "pageid": int(pid),
                "qid": page.get("pageprops", {}).get("wikibase_item"),
                "lat": coords.get("lat"),
                "lon": coords.get("lon"),
                "url": f"https://en.wikipedia.org/?curid={pid}"
            }
    return details

def main(out_csv="wikipedia_buildings_baseline.csv"):
    members = list_category_members(CAT_TITLE)
    pageids = [m["pageid"] for m in members if m["ns"] == 0]  # content pages
    details = fetch_page_details(pageids)

    now = datetime.utcnow().isoformat()
    with open(out_csv, "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(["source","source_id","name","primary_category","lat","lon","source_url","last_seen","wikidata_qid"])
        for pid in pageids:
            d = details.get(pid, {})
            w.writerow([
                "wikipedia",
                pid,
                d.get("title",""),
                "",  # fill later if you want to map categories
                d.get("lat",""),
                d.get("lon",""),
                d.get("url",""),
                now,
                d.get("qid","")
            ])

if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv)>1 else "wikipedia_buildings_baseline.csv"
    main(out)
