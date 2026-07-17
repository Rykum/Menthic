import 'package:oracle_calibration/oracle_calibration.dart';
import 'package:oracle_store/oracle_store.dart';
import 'package:test/test.dart';

void main() {
  test('store com previsões+desfechos -> extract -> buildReport', () async {
    final store = InMemoryEventStore();
    final day = DateTime.utc(2026, 7, 17, 8);
    // duas previsões resolvidas
    await store.append(previsaoEmitida(ts: day, cid: 'a', p: 0.9));
    await store.append(tarefaConcluida(ts: day, cid: 'a', atrasoMin: 0));
    await store.append(previsaoEmitida(ts: day, cid: 'b', p: 0.2));
    await store.append(
      EventDraft(
        ts: day,
        type: EventTypes.tarefaNaoConcluida,
        payload: const {'cid': 'b'},
      ),
    );

    final pairs = await const CalibrationExtractor().extract(store);
    final report = buildReport(pairs);
    expect(report.n, 2);
    expect(
      report.brier,
      closeTo((0.01 + 0.04) / 2, 1e-12),
    ); // (0.9-1)^2,(0.2-0)^2
    expect(report.gate.passed, isFalse); // n < 120
  });

  test('Platt recalibra pares extraídos e reduz viés', () async {
    final store = InMemoryEventStore();
    final day = DateTime.utc(2026, 7, 17, 8);
    for (var i = 0; i < 50; i++) {
      await store.append(previsaoEmitida(ts: day, cid: 'c$i', p: 0.8));
      await store.append(tarefaConcluida(ts: day, cid: 'c$i', atrasoMin: 0));
    }
    for (var i = 0; i < 50; i++) {
      await store.append(previsaoEmitida(ts: day, cid: 'd$i', p: 0.8));
      await store.append(
        EventDraft(
          ts: day,
          type: EventTypes.tarefaNaoConcluida,
          payload: {'cid': 'd$i'},
        ),
      );
    }
    final pairs = await const CalibrationExtractor().extract(store);
    final cal = PlattCalibrator.fit(pairs);
    final recal = pairs.map((x) => PredOutcome(cal.apply(x.p), x.o)).toList();
    expect(
      calibrationInTheLarge(recal),
      lessThan(calibrationInTheLarge(pairs)),
    );
  });
}
