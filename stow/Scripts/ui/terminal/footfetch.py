#!/usr/bin/env python3
import platform, psutil
from datetime import datetime
from rich.console import Console
from rich.table import Table
from rich.progress import Progress, BarColumn, TextColumn, ProgressColumn
from rich.text import Text
from rich.panel import Panel

console = Console()

# --- Helpers ---
def format_bytes(size):
    for unit in ['B','KB','MB','GB','TB']:
        if size < 1024: return f"{size:.1f} {unit}"
        size /= 1024

def uptime():
    delta = datetime.now() - datetime.fromtimestamp(psutil.boot_time())
    return str(delta).split('.')[0]



# --- System Info Table ---
def system_table():
    table = Table(show_edge=False, show_header=False, box=None)
    table.add_column("Item", style="bold cyan")
    table.add_column("Valor", style="bold magenta")

    mem = psutil.virtual_memory()
    disk = psutil.disk_usage('/')
    
    table.add_row("OS", f"{platform.system()} {platform.release()}")
    table.add_row("Kernel", platform.version())
    table.add_row("CPU", f"{platform.processor()} ({psutil.cpu_count(logical=False)}C / {psutil.cpu_count(logical=True)}L)")
    table.add_row("RAM", f"{format_bytes(mem.used)} / {format_bytes(mem.total)} ({mem.percent}%)")
    table.add_row("Disco /", f"{format_bytes(disk.used)} / {format_bytes(disk.total)} ({disk.percent}%)")
    table.add_row("Uptime", uptime())
    return table



# --- Main ---
if __name__ == "__main__":
    console.clear()
    console.print(Panel(Text("System Information", justify="center", style="bold underline")))
    console.print(system_table())

