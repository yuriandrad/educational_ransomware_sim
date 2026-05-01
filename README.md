# Simulador Educacional de Ransomware

Este projeto contem um simulador seguro de ransomware em Bash para treinamentos defensivos, aulas, laboratorios e demonstracoes de resposta a incidentes.

O script **nao criptografa, altera ou renomeia arquivos reais** no diretorio alvo. Ele apenas copia os arquivos para uma pasta temporaria e renomeia essas copias com a extensao `.locked`.

## Arquivo

- `educational_ransomware_sim.sh`: script principal da simulacao.

## O Que Ele Faz

- Exige um diretorio alvo definido pelo usuario.
- Copia arquivos do diretorio alvo para uma pasta temporaria.
- Renomeia apenas as copias com a extensao `.locked`.
- Gera um `README_RESCUE_SIMULADO.txt` com uma mensagem de resgate falsa.
- Cria um marcador interno para identificar a pasta como simulacao.
- Permite rollback removendo somente uma pasta temporaria marcada pelo proprio script.

## O Que Ele Nao Faz

- Nao criptografa arquivos.
- Nao modifica arquivos originais.
- Nao renomeia arquivos originais.
- Nao executa propagacao.
- Nao coleta credenciais.
- Nao se conecta a rede.

## Requisitos

- Bash
- Utilitarios Unix comuns: `find`, `cp`, `mktemp`, `date`, `dirname`, `basename`

## Uso

Primeiro, torne o script executavel:

```bash
chmod +x educational_ransomware_sim.sh
```

Execute uma simulacao:

```bash
./educational_ransomware_sim.sh --simulate --target ./laboratorio
```

Ao final, o script exibira o caminho da pasta temporaria da simulacao, por exemplo:

```text
/tmp/ransomware-sim-20260501-120000.ABC123
```

Dentro dessa pasta, os arquivos copiados ficarao em `files/` com a extensao `.locked`, e a nota simulada ficara em `README_RESCUE_SIMULADO.txt`.

## Rollback

Para remover a simulacao:

```bash
./educational_ransomware_sim.sh --rollback --simulation /tmp/ransomware-sim-20260501-120000.ABC123
```

O rollback so remove diretorios temporarios com nome `ransomware-sim-*` que contenham o marcador interno `.educational_ransomware_simulation`.

## Travas de Seguranca

O script recusa alvos amplos ou sensiveis, incluindo:

- `/`
- `/etc`
- `/usr`
- `/var`
- `/tmp`
- `$HOME`

Essas travas reduzem o risco de uso acidental em locais inadequados.

## Exemplo de Laboratorio

```bash
mkdir -p laboratorio/docs
printf 'relatorio financeiro simulado\n' > laboratorio/docs/relatorio.txt
printf 'anotacoes de aula\n' > laboratorio/notas.txt

./educational_ransomware_sim.sh --simulate --target ./laboratorio
```

Depois da execucao, confira que os arquivos originais continuam intactos:

```bash
find laboratorio -type f
```

E confira os arquivos simulados na pasta temporaria exibida pelo script.
