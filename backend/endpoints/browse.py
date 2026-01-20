from fastapi import APIRouter, HTTPException, Response
from fastapi.responses import HTMLResponse, FileResponse
from pathlib import Path
from urllib.parse import quote
import os

router = APIRouter(tags=["browse"])

UPLOAD_DIR = Path("uploads")


def _safe_resolve(path: Path) -> Path:
    # Resolve and ensure it's inside uploads
    resolved = path.resolve()
    uploads_resolved = UPLOAD_DIR.resolve()
    if not str(resolved).startswith(str(uploads_resolved)):
        raise HTTPException(status_code=403, detail="Access denied")
    return resolved


@router.get("/uploads/", response_class=HTMLResponse)
async def list_uploads_root():
    target = _safe_resolve(UPLOAD_DIR)
    return await _dir_listing_response(target, "")


@router.get("/uploads/{path:path}", response_class=HTMLResponse)
async def browse_uploads(path: str):
    target = _safe_resolve(UPLOAD_DIR / path)
    if target.exists() and target.is_file():
        # For files, serve the actual file so browsers can display it inline
        return FileResponse(target)

    if not target.exists():
        raise HTTPException(status_code=404, detail="Not found")

    return await _dir_listing_response(target, path)


async def _dir_listing_response(target: Path, rel_path: str) -> HTMLResponse:
    items = sorted(list(target.iterdir()), key=lambda p: (not p.is_dir(), p.name.lower()))

    lines = [
        "<html><head><meta charset=\"utf-8\"><title>Uploads Browser</title></head><body>",
        f"<h2>Index of /uploads/{rel_path}</h2>",
        "<ul style=\"list-style:none; padding-left:0\">",
    ]

    # Parent link if not root
    if rel_path:
        parent = str(Path(rel_path).parent).replace("\\", "/")
        parent_prefix = f"/browse/uploads/{quote(parent)}" if parent != "." else "/browse/uploads/"
        lines.append(f"<li><a href=\"{parent_prefix}\">[.. Parent]</a></li>")

    for p in items:
        name = p.name
        # Create a relative URL for the mounted static files (view) and for browse (navigate into dirs)
        rel = (Path(rel_path) / name).as_posix() if rel_path else Path(name).as_posix()
        encoded = quote(rel)
        if p.is_dir():
            link = f"/browse/uploads/{encoded}/"
            lines.append(f"<li>📁 <a href=\"{link}\">{name}/</a></li>")
        else:
            # Link to the static mount for direct viewing
            static_link = f"/uploads/{encoded}"
            size = _human_readable_size(p.stat().st_size)
            lines.append(f"<li>📄 <a href=\"{static_link}\">{name}</a> <small>({size})</small></li>")

    lines.append("</ul>")
    lines.append("</body></html>")

    return HTMLResponse("\n".join(lines))


def _human_readable_size(size: int) -> str:
    # Simple utility to display bytes
    for unit in ['B', 'KB', 'MB', 'GB', 'TB']:
        if size < 1024:
            return f"{size:.0f}{unit}"
        size /= 1024
    return f"{size:.0f}PB"