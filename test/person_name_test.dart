// Le nom s'affiche toujours de la meme facon, quelle que soit la frappe de
// la gestion au moment de creer le compte.
import 'package:flutter_test/flutter_test.dart';
import 'package:gestimou_mobile/data/person_name.dart';

void main() {
  test('majuscule initiale, quelle que soit la saisie', () {
    expect(PersonName.format('amel'), 'Amel');
    expect(PersonName.format('AMEL'), 'Amel');
    expect(PersonName.format('  amel   benelhadj '), 'Amel Benelhadj');
    expect(PersonName.format('aMeL BeNeLhAdJ'), 'Amel Benelhadj');
  });

  test('noms composes', () {
    expect(PersonName.format('jean-pierre'), 'Jean-Pierre');
    expect(PersonName.format("d'amel"), "D'Amel");
  });

  test('particules en minuscules, sauf en tete', () {
    expect(PersonName.format('amel de la tour'), 'Amel de la Tour');
    expect(PersonName.format('de la tour'), 'De la Tour');
    expect(PersonName.format('mohamed ben ali'), 'Mohamed ben Ali');
  });

  test('prenom seul pour la salutation', () {
    expect(PersonName.firstName('amel benelhadj'), 'Amel');
    expect(PersonName.firstName(''), '');
    expect(PersonName.firstName(null), '');
  });

  test('accents preserves', () {
    expect(PersonName.format('éric'), 'Éric');
    expect(PersonName.format('ÉRIC'), 'Éric');
  });
}
