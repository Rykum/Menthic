import 'package:oracle_store/oracle_store.dart';
import 'event_store_contract.dart';

void main() {
  runEventStoreContract(() => SqliteEventStore.memory());
}
