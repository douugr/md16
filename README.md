# MD16

Emulador de **Mega Drive / Genesis** (também Master System, Game Gear e SG-1000) feito para um **iPad antigo com iOS 8**. Foi testado num iPad 3 (A5X, armv7) com iOS 8.4.1 e jailbreak.

É um frontend libretro próprio, escrito em Objective-C/UIKit, que compila o core [Genesis Plus GX](https://github.com/libretro/Genesis-Plus-GX) junto no app. Os controles Bluetooth funcionam via [BTstack](https://github.com/bluekitchen/btstack). Ele existe porque as builds de RetroArch para iOS não rodam mais no iOS 8. (O projeto começou com o nome Retro16.)

## Funcionalidades

- Visual inspirado na época dos 16 bits: grade cinza sobre preto, letreiros cromados, vermelho e faixas diagonais. A biblioteca mostra os jogos como etiquetas de cartucho
- Vídeo em OpenGL ES 2 (RGB565), com imagem nítida (pixels) ou suavizada
- Áudio por RemoteIO, com o ritmo do jogo guiado pela fila de som: se o iPad atrasa, o emulador roda um quadro extra sem desenhar, e o jogo não fica lento nem picota
- Controle na tela: direcional de 8 direções, A/B/C em arco como no controle original, START e botão de menu
- **Controle Bluetooth** (testado com o 8BitDo Pro 2) pelo BTstack, com:
  - assistente que aprende os botões ("aperte: Cima, A, B, C, Start…");
  - direcional digital e analógico esquerdo;
  - reconexão automática.
  O BTstack roda numa thread própria, separada do jogo.
- **Envio de ROMs pelo navegador:** a tela "Enviar ROMs" mostra um endereço (`http://<ip-do-ipad>:8080`). No computador, é só abrir a página e arrastar os arquivos, sem cabo nem SSH
- **Patch automático IPS/BPS:** um `.ips`/`.bps` com o mesmo nome da ROM é aplicado ao abrir o jogo, numa cópia temporária. A ROM original não é alterada. No BPS, o CRC é conferido e o app avisa se o patch é de outra versão da ROM
- Estados salvos em 3 slots manuais, mais um salvamento automático ao sair, com a opção "Continuar de onde parou?" ao abrir o jogo
- SRAM (saves internos do cartucho) gravada automaticamente
- Medidor de desempenho opcional (quadros por segundo e tempo de emulação e de desenho)

No iPad 3, o Sonic 2 roda a 60 fps: cerca de 5–7 ms de emulação por quadro.

## Requisitos

- iPad com iOS 8 e jailbreak, com:
  - **OpenSSH**, para instalar;
  - **BTstack** (pacote Cydia `ch.ringwald.btstack` 1.1), para os controles.
- Mac com o **Xcode 13.4.1** extraído. Só o toolchain é usado; versões mais novas não geram armv7.
- `ldid` (`brew install ldid`)
- Acesso SSH ao iPad como root, de preferência com chave

O app é instalado em `/Applications`, fora do sandbox, porque só assim ele consegue falar com o BTdaemon.

## Compilar e instalar

```bash
export X13=/caminho/para/Xcode-13.4.1.app/Contents/Developer   # padrão: ../Xcode-13.4.1.app
export IPAD=192.168.x.x                                          # IP do iPad

./build.sh            # compila build/MD16.app
./build.sh install    # compila e instala no iPad via SSH
./build.sh roms       # envia as ROMs de ../roms para o iPad
```

Na primeira vez, o `build.sh` baixa o Genesis Plus GX (num commit fixo) e compila o core, o que leva alguns minutos. Ele também copia a `libBTstack.dylib` do próprio iPad e gera um stub para o link: a dylib do pacote só tem as fatias armv6 e arm64, então o stub reetiqueta a armv6 como armv7 (`tools/make_link_stub.py`).

## Uso

- As ROMs ficam em `Documents/MD16/roms`. Mande pela tela **Enviar ROMs** ou por `./build.sh roms`. Você precisa ter as suas próprias: nenhuma ROM acompanha este projeto.
- **Controle:**
  1. Deixe o Bluetooth do iOS **desligado** e o **Wi-Fi ligado**. No iPad 3 eles dividem o chip, e sem o Wi-Fi o BTstack não inicializa.
  2. Coloque o controle em modo de pareamento.
  3. Toque em Controle → Procurar controles, toque no controle encontrado e depois em Configurar botões.
- **Menu do jogo:** botão no canto superior direito, ou um botão do controle configurado como "Menu".

## Licenças

- O código deste repositório é do autor. O ícone é original, feito para o projeto.
- O **Genesis Plus GX** não é incluído aqui: ele é baixado na hora de compilar e segue a licença dele, de uso **não comercial**.
- Os headers em `vendor/btstack` são do BTstack (© BlueKitchen GmbH / Matthias Ringwald) e seguem a licença do BTstack.
