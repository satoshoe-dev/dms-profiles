# Profiles

[English](README.md) · [Deutsch](README.de.md) · [Español](README.es.md) · [Français](README.fr.md) · [Italiano](README.it.md) · **Português** · [Русский](README.ru.md) · [日本語](README.ja.md) · [简体中文](README.zh_CN.md)

Um plugin para o [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell) que salva a aparência do seu shell com um nome e permite alternar entre essas aparências. Um perfil guarda o tema e a cor de destaque, o modo claro ou escuro, o papel de parede, suas barras, a moldura, a transparência, as fontes, as animações e os widgets da área de trabalho com suas posições.

![Profiles](assets/screenshot.png)

Passo a passo com imagens: [guia de instalação e configuração](docs/GUIDE.pt.md).

## Troca de perfil

Abra o seletor com um atalho de teclado e escolha um perfil. A tela para por um instante (cerca de 0,2 s) enquanto é capturada. Depois a transição passa na hora da imagem antiga para o papel de parede do novo perfil. Enquanto isso o DMS aplica o perfil, e quando ele fica pronto, barras, moldura, janelas e widgets aparecem aos poucos sobre o novo fundo. Você não vê o shell mudando parte por parte.

Perfis sem papel de parede próprio usam a sequência anterior: a imagem capturada fica na tela até o perfil ser aplicado, e então a transição revela a área de trabalho já pronta. A duração da transição pode ser ajustada nas configurações (1,2 s por padrão).

Há 29 transições para escolher, entre elas esmaecer, cortina, círculo, portas, persianas, derreter, estilhaços, um CRT desligando, chuvisco e cinco efeitos de hack. A opção Aleatória pode ser limitada às que você preferir. Na maioria das animações, a borda brilha na cor de destaque do novo perfil.

## Seletor

O seletor tem quatro visualizações: uma fileira sobre um painel, a mesma fileira sem o painel, um carrossel com o perfil atual grande no meio e uma grade que ocupa a tela toda. As prévias podem ser em retrato, paisagem, quadrado, círculo, hexágono, losango ou inclinado (retrato com a moldura inclinada). Na grade, hexágonos e losangos ficam dispostos como um favo de mel, com o mesmo espaçamento das suas janelas. Contorno, brilho, marca de seleção e arredondamento dos cantos podem ser desligados ou ajustados.

A roda do mouse e as setas movem a seleção, Enter ou um clique aplica, Esc fecha o seletor.

## Salvamento

As alterações que você faz nas configurações do DMS são salvas no perfil ativo depois de alguns segundos. Cada perfil lembra como estava quando foi ativado, então dá para desfazer as alterações na página de configurações. O papel de parede é copiado para dentro do perfil, então mover ou apagar o arquivo original não estraga nada.

Os perfis ficam em `~/.config/DankMaterialShell/profiles/`, uma pasta por perfil.

## Configurações de outros plugins

As configurações de plugins também podem fazer parte de um perfil. Informe os IDs dos plugins em Configurações → Plugins → Profiles → Plugins salvos com o perfil, por exemplo `audioFx`.

## Coisas fora do DMS

Cores do terminal, temas do navegador ou regras do compositor que o DMS não gerencia podem ser tratados com dois comandos opcionais:

- O comando ao salvar roda quando um perfil é salvo. O JSON que ele imprimir fica guardado no perfil como `extras`.
- O comando ao aplicar roda durante a troca, logo depois que as novas configurações são gravadas. A nova área de trabalho só aparece quando ele termina. Ele recebe `DMS_PROFILE_DIR`, `DMS_PROFILE_SLUG`, `DMS_PROFILE_NAME` e `DMS_PROFILE_NEW_COLORS` (1 se novas cores estiverem sendo geradas). O arquivo do perfil é `$DMS_PROFILE_DIR/profile.json`.

Um pequeno exemplo que guarda a fonte da interface GTK por perfil:

```sh
# save command
printf '{"font": "%s"}' "$(gsettings get org.gnome.desktop.interface font-name | tr -d "'")"

# apply command
gsettings set org.gnome.desktop.interface font-name \
  "$(python3 -c 'import json,os; print(json.load(open(os.environ["DMS_PROFILE_DIR"] + "/profile.json"))["extras"]["font"])')"
```

## Requisitos

DankMaterialShell 1.6.1 ou mais recente. Para a transição, a tela é capturada com `grim` se ele estiver instalado, senão com `dms screenshot`, que já vem com o DMS. Eu uso o plugin no niri. Espaçamento entre janelas, arredondamento dos cantos e largura da borda são gravados pelo próprio DMS na configuração do compositor, então devem acompanhar o perfil também em outros compositores suportados pelo DMS.

## Instalação

Pelo registro de plugins:

```sh
dms plugins install dmsProfiles
dms ipc call plugins enable dmsProfiles
```

Ele também aparece no DMS em Configurações → Plugins → Navegar. Para instalar a partir do repositório:

```sh
git clone https://github.com/satoshoe-dev/dms-profiles ~/.config/DankMaterialShell/plugins/DmsProfiles
dms ipc call plugins enable dmsProfiles
```

Depois adicione um atalho de teclado, por exemplo no niri:

```kdl
Mod+Shift+M { spawn "dms" "ipc" "call" "profiles" "toggle"; }
```

## IPC

```sh
dms ipc call profiles toggle
dms ipc call profiles list
dms ipc call profiles apply <slug>
dms ipc call profiles create <name>
dms ipc call profiles save
dms ipc call profiles rename <slug> <new name>
dms ipc call profiles remove <slug>
dms ipc call profiles move <slug> left|right|<position>
dms ipc call profiles reset <slug>
dms ipc call profiles previewTransition <type>
dms ipc call profiles status
```

## Traduções

O plugin está disponível em alemão, espanhol, francês, italiano, português, russo, japonês e chinês simplificado e segue o idioma definido no DMS. Se alguma tradução estiver estranha, pull requests são bem-vindos.

## Observação

Escrevi este plugin com a ajuda do Claude (Anthropic) e o uso todos os dias no meu próprio desktop.

## Licença

[MIT](LICENSE)
