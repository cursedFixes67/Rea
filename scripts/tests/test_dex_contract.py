"""Regression tests using actual D8 output, including a referenced absent class."""
from pathlib import Path
import sys
import unittest
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from dex_contract import DexClass, read_dex, check_contract, resolve_member


class DexContractTest(unittest.TestCase):
    def setUp(self):
        self.inventory = read_dex(Path(__file__).with_name('fixtures').joinpath('linkage.dex').read_bytes())

    def test_referenced_class_and_method_do_not_count_as_definitions(self):
        self.assertIn('Lfixture/External;', self.inventory.types)
        self.assertNotIn('Lfixture/External;', self.inventory.classes)
        self.assertIn(('Lfixture/External;', 'absent', '()Ljava/lang/String;'), self.inventory.methods)
        missing = check_contract(self.inventory.classes, {
            'types': ['Lfixture/External;'],
            'methods': [['Lfixture/External;', 'absent', '()Ljava/lang/String;']], 'fields': [],
        })
        self.assertEqual(len(missing), 2)

    def test_actual_member_descriptors_and_interfaces_resolve(self):
        classes = self.inventory.classes
        self.assertIn('Lfixture/Parent;', classes['Lfixture/Host;'].parents)
        self.assertTrue(resolve_member(classes, 'Lfixture/Host;', ('inherited', '()Ljava/lang/String;'), 'methods'))
        self.assertFalse(resolve_member(classes, 'Lfixture/Host;', ('inherited', '(I)Ljava/lang/String;'), 'methods'))
        self.assertTrue(resolve_member(classes, 'Lfixture/Host;', ('value', 'I'), 'fields'))
        self.assertFalse(resolve_member(classes, 'Lfixture/Host;', ('value', 'J'), 'fields'))

    def test_constructors_are_not_inherited_and_cycles_terminate(self):
        classes = self.inventory.classes
        classes['Lfixture/Child;'] = DexClass(parents=['Lfixture/Host;'])
        self.assertTrue(resolve_member(classes, 'Lfixture/Child;', ('inherited', '()Ljava/lang/String;'), 'methods'))
        self.assertFalse(resolve_member(classes, 'Lfixture/Child;', ('<init>', '()V'), 'methods'))
        classes['Lfixture/Cycle;'] = DexClass(parents=['Lfixture/Cycle;'])
        self.assertFalse(resolve_member(classes, 'Lfixture/Cycle;', ('missing', '()V'), 'methods'))

    def test_malformed_input_is_rejected(self):
        with self.assertRaises(ValueError):
            read_dex(b'not a dex')
