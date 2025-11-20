Current notes for Front end linking:

* Endpoint URL (dev): http://localhost:8001/chat (host:8001 → container:8000 in the current compose setup).
* Content type: application/json.
* Required JSON body fields:
    * question (string) — required
    * chunk_type (string) — optional, default "char-split" (probably prefer "recursive-split")
    * top_k (int) — optional, default 5
    * return_docs (bool) — optional, default false (probably prefer false)
* Example success response:{ "answer": "…", "documents": [...]}
    * documents only present if return_docs true
Quick example requests the frontend can use
* curl: 
    * curl -X POST http://localhost:8001/chat-H "Content-Type: application/json"-d '{"question":"When was Memorial Hall built?","chunk_type":"recursive-split","top_k":5}'
* browser fetch:
    * const resp = await fetch("http://localhost:8001/chat", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
            question: "When was Memorial Hall built?",
            chunk_type: "recursive-split",
            top_k: 5,
            return_docs: false
            })
            });
            const data = await resp.json();
            console.log(data.answer, data.documents);
* axios: 
    * import axios from "axios";
    const { data } = await axios.post("http://localhost:8001/chat", {
    question: "When was Memorial Hall built?",
    chunk_type: "recursive-split",
    top_k: 5,
    return_docs: true
    }, { headers: { "Content-Type": "application/json" }});
    console.log(data);

Embeddings:
* Currently, there is no DB setup to store the embeddings. Things are locally saved and stored.
* In the future, I would want to make a DB to pull embeddings from, but I prioritized a working product and currently the number of embeddings is very small.