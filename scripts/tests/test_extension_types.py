"""Regression cases for the release DEX metadata gate."""
import sys
from pathlib import Path
import unittest
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from verify_extension_types import inspect_dump


class TypeMetadataTest(unittest.TestCase):
    def test_method_signature_cannot_mask_missing_class_signature(self):
        dump = '''Class #17 annotations:
Annotations on class
  VISIBILITY_SYSTEM Ldalvik/annotation/InnerClass; accessFlags=25 name=null
Annotations on method #10 'call'
  VISIBILITY_SYSTEM Ldalvik/annotation/Signature; value={ "Luy/kohesive/injekt/api/FullTypeReference<" "Landroid/content/Context;" ">;" }
Class #17            -
  Class descriptor  : 'La;'
  Superclass        : 'Luy/kohesive/injekt/api/FullTypeReference;'
'''
        self.assertEqual(inspect_dump(dump.splitlines()), [('La;', '')])

    def test_class_signature_is_associated_by_dex_class_number(self):
        dump = '''Class #19 annotations:
Annotations on class
  VISIBILITY_SYSTEM Ldalvik/annotation/Signature; value={ "Luy/kohesive/injekt/api/FullTypeReference<" "Landroid/content/Context;" ">;" }
Class #19            -
  Class descriptor  : 'LToken;'
  Superclass        : 'Luy/kohesive/injekt/api/FullTypeReference;'
Class #20            -
  Class descriptor  : 'LBroken;'
  Superclass        : 'Luy/kohesive/injekt/api/FullTypeReference;'
'''
        self.assertEqual(inspect_dump(dump.splitlines()), [
            ('LToken;', 'Luy/kohesive/injekt/api/FullTypeReference<Landroid/content/Context;>;'),
            ('LBroken;', ''),
        ])


if __name__ == '__main__':
    unittest.main()
