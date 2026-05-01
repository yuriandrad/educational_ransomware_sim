#!/usr/bin/env bash
set -euo pipefail

# Educational ransomware simulator.
# It never encrypts or renames files in the target directory. It only copies
# target files into a temporary simulation directory and renames those copies.

SCRIPT_NAME="$(basename "$0")"
MARKER_FILE=".educational_ransomware_simulation"
README_FILE="README_RESCUE_SIMULADO.txt"

usage() {
  cat <<EOF
Uso:
  $SCRIPT_NAME --simulate --target DIRETORIO
  $SCRIPT_NAME --rollback --simulation DIRETORIO_DA_SIMULACAO

Opcoes:
  --simulate              Copia arquivos do alvo para uma pasta temporaria e
                          renomeia as copias com extensao .locked.
  --target DIRETORIO      Diretorio especifico escolhido pelo usuario.
  --rollback              Remove uma pasta de simulacao criada por este script.
  --simulation DIRETORIO  Pasta temporaria criada por --simulate.
  --help                  Mostra esta ajuda.

Exemplos:
  $SCRIPT_NAME --simulate --target ./laboratorio
  $SCRIPT_NAME --rollback --simulation /tmp/ransomware-sim-20260501-120000.abc123
EOF
}

fail() {
  printf 'Erro: %s\n' "$1" >&2
  exit 1
}

absolute_path() {
  local path="$1"

  if [[ ! -e "$path" ]]; then
    fail "o caminho nao existe: $path"
  fi

  (
    cd "$path"
    pwd -P
  )
}

is_dangerous_target() {
  local target="$1"
  local home_dir="${HOME:-}"

  [[ "$target" == "/" ]] && return 0
  [[ -n "$home_dir" && "$target" == "$home_dir" ]] && return 0
  [[ "$target" == "/tmp" ]] && return 0
  [[ "$target" == "/var" ]] && return 0
  [[ "$target" == "/usr" ]] && return 0
  [[ "$target" == "/etc" ]] && return 0

  return 1
}

create_ransom_note() {
  local output_dir="$1"

  cat > "$output_dir/$README_FILE" <<'EOF'
=== SIMULACAO EDUCACIONAL DE RANSOMWARE ===

Este README faz parte de um exercicio defensivo.
Nenhum arquivo real foi criptografado, renomeado ou sequestrado.

O que aconteceu nesta simulacao:
- Os arquivos do diretorio alvo foram copiados para uma pasta temporaria.
- Apenas as copias receberam a extensao .locked.
- Esta nota simula uma mensagem de resgate para fins de treinamento.

Como reverter:
Execute o script com --rollback apontando para esta pasta de simulacao.

Exemplo:
  ./educational_ransomware_sim.sh --rollback --simulation CAMINHO_DESTA_PASTA

Nunca pague resgates reais. Em incidentes reais, isole o sistema, preserve
evidencias, acione resposta a incidentes e restaure a partir de backups
confiaveis.
EOF
}

simulate() {
  local target="$1"
  local target_abs
  target_abs="$(absolute_path "$target")"

  [[ -d "$target_abs" ]] || fail "o alvo precisa ser um diretorio: $target"

  if is_dangerous_target "$target_abs"; then
    fail "recusando alvo amplo ou sensivel: $target_abs"
  fi

  local timestamp
  timestamp="$(date +%Y%m%d-%H%M%S)"

  local simulation_dir
  simulation_dir="$(mktemp -d "${TMPDIR:-/tmp}/ransomware-sim-${timestamp}.XXXXXX")"

  printf 'Educational ransomware simulation\n' > "$simulation_dir/$MARKER_FILE"
  printf 'Target: %s\nCreated: %s\n' "$target_abs" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$simulation_dir/$MARKER_FILE"

  local copied_count=0
  local skipped_count=0

  while IFS= read -r -d '' source_file; do
    local relative_path destination_dir destination_file
    relative_path="${source_file#"$target_abs"/}"
    destination_dir="$simulation_dir/files/$(dirname "$relative_path")"
    destination_file="$destination_dir/$(basename "$relative_path").locked"

    mkdir -p "$destination_dir"

    if cp -p "$source_file" "$destination_file"; then
      copied_count=$((copied_count + 1))
    else
      skipped_count=$((skipped_count + 1))
      printf 'Aviso: falha ao copiar %s\n' "$source_file" >&2
    fi
  done < <(find "$target_abs" -type f -not -name '*.locked' -print0)

  create_ransom_note "$simulation_dir"

  cat <<EOF
Simulacao concluida com seguranca.

Diretorio alvo original:
  $target_abs

Pasta temporaria da simulacao:
  $simulation_dir

Arquivos copiados e renomeados:
  $copied_count

Arquivos ignorados por erro de copia:
  $skipped_count

Rollback:
  $SCRIPT_NAME --rollback --simulation "$simulation_dir"
EOF
}

rollback() {
  local simulation_dir="$1"
  local simulation_abs
  simulation_abs="$(absolute_path "$simulation_dir")"

  [[ -d "$simulation_abs" ]] || fail "a simulacao precisa ser um diretorio: $simulation_dir"
  [[ -f "$simulation_abs/$MARKER_FILE" ]] || fail "diretorio sem marcador de simulacao: $simulation_abs"
  [[ "$simulation_abs" == /tmp/ransomware-sim-* || "$simulation_abs" == "${TMPDIR:-/tmp}"/ransomware-sim-* ]] || \
    fail "por seguranca, rollback so remove pastas temporarias ransomware-sim-*"

  rm -rf -- "$simulation_abs"
  printf 'Rollback concluido. Simulacao removida: %s\n' "$simulation_abs"
}

mode=""
target=""
simulation=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --simulate)
      mode="simulate"
      shift
      ;;
    --rollback)
      mode="rollback"
      shift
      ;;
    --target)
      [[ $# -ge 2 ]] || fail "--target requer um diretorio"
      target="$2"
      shift 2
      ;;
    --simulation)
      [[ $# -ge 2 ]] || fail "--simulation requer um diretorio"
      simulation="$2"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      fail "opcao desconhecida: $1"
      ;;
  esac
done

case "$mode" in
  simulate)
    [[ -n "$target" ]] || fail "use --target DIRETORIO com --simulate"
    [[ -z "$simulation" ]] || fail "--simulation e usado apenas com --rollback"
    simulate "$target"
    ;;
  rollback)
    [[ -n "$simulation" ]] || fail "use --simulation DIRETORIO_DA_SIMULACAO com --rollback"
    [[ -z "$target" ]] || fail "--target e usado apenas com --simulate"
    rollback "$simulation"
    ;;
  *)
    usage
    exit 1
    ;;
esac
