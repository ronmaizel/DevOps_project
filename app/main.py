from fastapi import FastAPI # type: ignore
app = FastAPI()
@app.get("/")
def read_root():
    return {"status code 200"}