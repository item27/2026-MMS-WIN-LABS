#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10"
# dependencies = [
#   "markdown>=3.6,<4",
#   "pymupdf>=1.24,<2",
#   "weasyprint>=62,<70",
# ]
# ///
"""Layout regression checks using the repository's actual screenshots."""

import runpy
import tempfile
import unittest
from pathlib import Path

import pymupdf

ROOT = Path(__file__).resolve().parent.parent
RENDER = runpy.run_path(str(ROOT / "scripts" / "render"))["render_markdown"]
SCREENSHOT = ROOT / "lab-2" / "screenshots" / "011-client-pro-selected.png"


class ScreenshotLayoutTests(unittest.TestCase):
    def render(self, source):
        with tempfile.TemporaryDirectory(prefix="lab-render-") as directory:
            report = Path(directory) / "lab-99-report.md"
            report.write_text(source, encoding="utf-8")
            return pymupdf.open(stream=RENDER(report), filetype="pdf")

    def test_two_screenshots_and_captions_fit_one_page(self):
        source = (
            "## Настройка клиентской машины\n\n"
            "Проверили выбранную редакцию и параметры клиента перед "
            "подключением к домену. Результаты показаны на двух снимках\n\n"
            f"![Первый снимок]({SCREENSHOT.as_uri()})\n\n"
            "Рисунок 1: Выбранная редакция Windows 10 Pro\n\n"
            f"![Второй снимок]({SCREENSHOT.as_uri()})\n\n"
            "Рисунок 2: Повторная проверка выбранной редакции\n"
        )
        with self.render(source) as document:
            self.assertEqual(len(document), 1, "Two screenshots should share a page")
            self.assertEqual(len(document[0].get_image_info()), 2)
            self.assertIn("Рисунок 1:", document[0].get_text())
            self.assertIn("Рисунок 2:", document[0].get_text())

    def test_image_is_not_distorted_or_clipped(self):
        with self.render(f"![Снимок]({SCREENSHOT.as_uri()})\n") as document:
            page = document[0]
            image = page.get_image_info()[0]
            rectangle = pymupdf.Rect(image["bbox"])
            self.assertAlmostEqual(
                rectangle.width / rectangle.height,
                image["width"] / image["height"],
                places=4,
            )
            self.assertTrue(page.rect.contains(rectangle))
            self.assertGreaterEqual(rectangle.width, 300, "Screenshot became too small")

    def test_caption_stays_with_its_image_near_page_boundary(self):
        prefix = "Текст перед изображением\n\n" * 22
        source = (
            prefix
            + f"![Снимок]({SCREENSHOT.as_uri()})\n\n"
            + "Рисунок 1: Подпись должна остаться рядом со снимком\n"
        )
        with self.render(source) as document:
            image_pages = [page.number for page in document if page.get_image_info()]
            caption_pages = [page.number for page in document if "Рисунок 1:" in page.get_text()]
            self.assertEqual(image_pages, caption_pages)


if __name__ == "__main__":
    unittest.main()
