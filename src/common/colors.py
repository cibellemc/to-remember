PRIMARY = "#13a4ec"

TEXT_DARK = "#f6f7f8" 
TEXT_LIGHT = "#111618" 

BACKGROUND_DARK = "#101c22"
BACKGROUND_LIGHT = "#f6f7f8"

BORDER_LIGHT = "#e5e7eb" # (zinc-200)
BORDER_DARK = "#3f3f46"  # (zinc-700)

PLACEHOLDER_LIGHT = "#6b7280" # (zinc-500)

TEXT_SUBTLE = "#4b5563"
TEXT_WHITE = "#ffffff"
TEXT_MUTED = "#617c89" 

# common/Colors.py

import flet as ft

# Cores Principais
PRIMARY = ft.Colors.BLUE_ACCENT_400 # Seu azul principal
BACKGROUND_LIGHT = ft.Colors.GREY_50 # Fundo branco muito leve para contraste
BACKGROUND_DARK = ft.Colors.GREY_900 # Fundo escuro
ERROR_COLOR = ft.Colors.RED_500 # Cor para erros

# Cores de Texto (ajustadas para funcionar com LIGHT e DARK)
# Para modo LIGHT: TEXT_LIGHT será QUASE PRETO, TEXT_MUTED será CINZA ESCURO
# Para modo DARK:  TEXT_LIGHT será QUASE BRANCO, TEXT_MUTED será CINZA CLARO
TEXT_LIGHT = ft.Colors.GREY_900 # Usado para títulos e textos importantes em modo LIGHT
TEXT_MUTED = ft.Colors.GREY_700 # Usado para subtítulos, placeholders em modo LIGHT
TEXT_ON_PRIMARY = ft.Colors.WHITE # Texto sobre o botão primário