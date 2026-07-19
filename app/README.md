# menthic (app Flutter)

UI do Project Oracle sobre os 4 pacotes headless.

## Rodar (dev)
```bash
cd app
flutter pub get
flutter run -d chrome
```

## Estado
- Design system glass+neumorphism (`lib/design/`), paleta mint fiel aos protótipos.
- Telas: Splash, Login, Cadastro (auth stub local), Onboarding (cold-start →
  priors), Hoje (OracleAnswer real por eventos), Revisão noturna (desfechos →
  TwinLearner), Simular ("E se..." sem gravar), Meu Twin (Reality Model com
  incerteza) e Calibração (Brier + previsão×realidade).
- Dados: eventos em `PersistentEventStore` (shared_preferences); priors do twin
  serializados; SQLite fica p/ hardening Android.
- Aprendizado: a Revisão coleta `dur_real` (o otimismo de agenda aprende) e
  a leitura dos priors aplica confiança adaptativa (`agePriors`, meia-vida
  90 dias — evidência velha regride ao prior neutro).
- Estratégias: `suggestStrategies` (engine) avalia perturbações do dia pelo
  próprio simulador e o card mostra "Se seu objetivo é terminar tudo";
  tocar numa estratégia grava `estrategia_aceita` (base do meta-aprendizado).
- As 5 telas do blueprint doc 06 §9 estão completas. Próximo: hardening
  Android, integrações externas (`origin` já reserva o lugar).
