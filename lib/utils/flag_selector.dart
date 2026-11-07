import 'package:flutter/material.dart';
import 'package:traductor_app/utils/languages.dart';
import 'package:traductor_app/utils/neon_title.dart';

//Fila de banderas para elegir un idioma.
//La elegida brilla en neon; la bloqueada (elegida en la otra fila) se apaga.
class FlagSelector extends StatelessWidget {
  final Language selected;
  final Language blocked;
  final ValueChanged<Language> onSelected;

  const FlagSelector({
    super.key,
    required this.selected,
    required this.blocked,
    required this.onSelected,
  });

  //10.1 tamaño de cada bandera
  static const double flagWidth = 52;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        //10.2 FittedBox achica la fila en pantallas angostas
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final language in languages)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: _FlagOption(
                    language: language,
                    isSelected: language == selected,
                    isBlocked: language == blocked,
                    onTap: () => onSelected(language),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        //10.3 nombre del idioma elegido
        Text(
          selected.name,
          style: const TextStyle(
            color: neonMintText,
            fontFamily: 'monospace',
            fontSize: 14,
            shadows: [Shadow(color: neonMint, blurRadius: 6)],
          ),
        ),
      ],
    );
  }
}

//10.4 una bandera que se puede tocar
class _FlagOption extends StatelessWidget {
  final Language language;
  final bool isSelected;
  final bool isBlocked;
  final VoidCallback onTap;

  const _FlagOption({
    required this.language,
    required this.isSelected,
    required this.isBlocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: language.name,
      child: GestureDetector(
        //la bandera bloqueada no se puede elegir
        onTap: isBlocked ? null : onTap,
        child: MouseRegion(
          cursor: isBlocked
              ? SystemMouseCursors.forbidden
              : SystemMouseCursors.click,
          child: AnimatedScale(
            scale: isSelected ? 1.12 : 1.0,
            duration: const Duration(milliseconds: 180),
            child: AnimatedOpacity(
              opacity: isSelected ? 1 : (isBlocked ? 0.25 : 0.75),
              duration: const Duration(milliseconds: 180),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: isSelected ? neonMint : const Color(0xFF7F77DD),
                    width: 2,
                  ),
                  //resplandor neon solo en la elegida
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: neonMint.withAlpha(200),
                            blurRadius: 6,
                          ),
                          BoxShadow(
                            color: neonMint.withAlpha(110),
                            blurRadius: 16,
                          ),
                        ]
                      : const [],
                ),
                child: language.flag(FlagSelector.flagWidth),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
