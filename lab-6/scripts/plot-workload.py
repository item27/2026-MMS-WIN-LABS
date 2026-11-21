"""Build the comparison from the two CSV files exported with relog."""
import csv
import json
from datetime import datetime
from pathlib import Path
from statistics import mean

import matplotlib.pyplot as plt

LAB = Path(__file__).resolve().parents[1]
TIME_FORMAT = "%m/%d/%Y %H:%M:%S.%f"
METRICS = (
    (r"\processor(_total)\% processor time", "Загрузка CPU", "%", 1),
    (r"\memory\available mbytes", "Доступная память", "МиБ", 1),
    (r"\physicaldisk(_total)\disk bytes/sec", "Чтение и запись дисков", "МиБ/с", 1024**2),
    (r"\network interface(", "Трафик сетевого интерфейса", "КиБ/с", 1024),
)

def read_run(path):
    with path.open(encoding="utf-8-sig", newline="") as stream:
        index, *rows = csv.reader(stream)
    keys = [name.lower() for name in index]
    times = [datetime.strptime(row[0], TIME_FORMAT) for row in rows]
    seconds = [(time - times[0]).total_seconds() for time in times]
    series = []
    for pattern, _, _, scale in METRICS:
        columns = [i for i, key in enumerate(keys) if pattern in key]
        if not columns:
            raise ValueError(f"{pattern} missing in {path}")
        values = []
        for row in rows:
            sample = [float(row[i]) for i in columns if row[i].strip()]
            values.append(sum(sample) / scale if sample else float("nan"))
        series.append(values)
    return seconds, series

runs = {"Фоновый режим": "idle", "Копирование и SHA-256": "active"}
figure, axes = plt.subplots(2, 2, figsize=(10, 5.7), layout="constrained")
summary = {}
for (label, name), color in zip(runs.items(), ("#27667B", "#AA461B")):
    seconds, series = read_run(LAB / "evidence" / f"{name}.csv")
    values_summary = {}
    for axis, values, (_, title, unit, _) in zip(axes.flat, series, METRICS):
        axis.plot(seconds, values, marker=".", linewidth=1.5, label=label, color=color)
        axis.set(title=title, xlabel="Время от начала замера, с", ylabel=unit)
        axis.grid(alpha=0.25)
        valid = [item for item in values if item == item]
        values_summary[title] = {"samples": len(valid), "mean": mean(valid), "max": max(valid)}
    summary[name] = {"duration_seconds": seconds[-1], **values_summary}

for axis in axes.flat:
    axis.legend(loc="best", fontsize=8)
figure.savefig(LAB / "screenshots" / "10-workload-comparison.png", dpi=180)
print(json.dumps(summary, ensure_ascii=False, indent=2))
