import flet as ft
import random
import time
import asyncio
from common.colors import PRIMARY, BACKGROUND_LIGHT, TEXT_LIGHT, TEXT_MUTED

class MemoryCard(ft.Container):
    def __init__(self, icon_name, on_click_handler):
        super().__init__()
        self.icon_name = icon_name
        self.is_revealed = False
        self.is_matched = False
        self.on_click_handler = on_click_handler
        
        # Estilo do Card
        self.width = 80
        self.height = 80
        self.bgcolor = ft.Colors.BLUE_50
        self.border_radius = 12
        self.alignment = ft.alignment.center
        self.on_click = self.handle_click
        self.animate = ft.Animation(300, ft.AnimationCurve.EASE_IN_OUT)
        
        # Conteúdo (Ícone ou Interrogação)
        self.icon_control = ft.Icon(name=ft.Icons.QUESTION_MARK, size=40, color=PRIMARY)
        self.content = self.icon_control

    def reveal(self, update=True):
        self.is_revealed = True
        self.bgcolor = ft.Colors.WHITE
        self.border = ft.border.all(2, PRIMARY)
        self.icon_control.name = self.icon_name
        if update:
            self.update()

    def hide(self):
        if not self.is_matched:
            self.is_revealed = False
            self.bgcolor = ft.Colors.BLUE_50
            self.border = None
            self.icon_control.name = ft.Icons.QUESTION_MARK
            self.update()

    def match(self):
        self.is_matched = True
        self.bgcolor = ft.Colors.GREEN_100
        self.border = ft.border.all(2, ft.Colors.GREEN)
        self.icon_control.color = ft.Colors.GREEN
        self.icon_control.name = self.icon_name
        self.update()

    def handle_click(self, e):
        if not self.is_revealed and not self.is_matched:
            self.on_click_handler(self)

class MemoryGameView(ft.View):
    def __init__(self, page: ft.Page, auth_service):
        super().__init__(route="/game/memory", bgcolor=BACKGROUND_LIGHT)
        self.page = page
        self.auth_service = auth_service
        
        # Configurações do Jogo
        self.icons_pool = [
            ft.Icons.PETS, ft.Icons.AC_UNIT, ft.Icons.ACCESS_ALARM, 
            ft.Icons.AIRPLANEMODE_ACTIVE, ft.Icons.BEACH_ACCESS, ft.Icons.CAKE,
            ft.Icons.CAMERA, ft.Icons.DIRECTIONS_BIKE
        ]
        self.cards = []
        self.selected_cards = []
        self.mistakes = 0
        self.matches_found = 0
        self.start_time = 0
        self.is_locked = False 
        
        # UI Elements
        self.grid = ft.GridView(
            runs_count=4,
            max_extent=90,
            child_aspect_ratio=1.0,
            spacing=10,
            run_spacing=10,
            padding=20,
        )
        
        self.btn_start = ft.ElevatedButton(
            "Estou pronto! (Esconder cartas)", 
            on_click=self.start_game,
            bgcolor=PRIMARY, color=ft.Colors.WHITE,
            height=50,
            visible=False
        )
        
        self.info_text = ft.Text(
            "Memorize as posições...", 
            size=20, weight=ft.FontWeight.BOLD, color=TEXT_LIGHT, text_align=ft.TextAlign.CENTER
        )

        self.appbar = ft.AppBar(
            title=ft.Text("Jogo da Memória", color=TEXT_LIGHT),
            bgcolor=ft.Colors.WHITE,
            center_title=True,
            leading=ft.IconButton(ft.Icons.ARROW_BACK, icon_color=TEXT_LIGHT, on_click=lambda e: page.go("/dashboard/patient"))
        )

        self.controls = [
            ft.Container(
                content=ft.Column([
                    ft.Container(height=10),
                    self.info_text,
                    ft.Text("Encontre os pares correspondentes", color=TEXT_MUTED),
                    ft.Container(height=20),
                    ft.Container(
                        content=self.grid,
                        bgcolor=ft.Colors.WHITE,
                        border_radius=16,
                        padding=10,
                        shadow=ft.BoxShadow(blur_radius=10, color=ft.Colors.with_opacity(0.1, ft.Colors.BLACK))
                    ),
                    ft.Container(height=20),
                    self.btn_start
                ], horizontal_alignment=ft.CrossAxisAlignment.CENTER),
                padding=20,
                expand=True
            )
        ]
        
        # Inicializa
        self.setup_board(difficulty=4)

    def setup_board(self, difficulty):
        selected_icons = self.icons_pool[:difficulty]
        game_icons = selected_icons * 2
        random.shuffle(game_icons)
        
        self.cards = []
        self.grid.controls.clear()
        
        for icon in game_icons:
            card = MemoryCard(icon, self.on_card_click)
            # Passamos update=False porque o card ainda não está na página
            card.reveal(update=False) 
            self.cards.append(card)
            self.grid.controls.append(card)
            
        self.btn_start.visible = True
        # Não chamamos self.update() aqui pois o __init__ ainda não terminou de montar a view na página
        # O Flet fará a renderização inicial automaticamente

    def start_game(self, e):
        self.btn_start.visible = False
        self.info_text.value = "Valendo!"
        self.start_time = time.time()
        
        for card in self.cards:
            card.hide()
        self.update()

    def on_card_click(self, card):
        if self.is_locked: return
        if len(self.selected_cards) >= 2: return

        card.reveal()
        self.selected_cards.append(card)

        if len(self.selected_cards) == 2:
            self.check_match()

    def check_match(self):
        self.is_locked = True
        card1 = self.selected_cards[0]
        card2 = self.selected_cards[1]

        if card1.icon_name == card2.icon_name:
            card1.match()
            card2.match()
            self.matches_found += 1
            self.selected_cards.clear()
            self.is_locked = False
            self.check_win()
        else:
            self.mistakes += 1
            
            # Usando sleep para MVP, mas idealmente seria assíncrono
            card1.bgcolor = ft.Colors.RED_100
            card2.bgcolor = ft.Colors.RED_100
            card1.update()
            card2.update()
            
            time.sleep(0.8) 
            
            card1.hide()
            card2.hide()
            self.selected_cards.clear()
            self.is_locked = False

    def check_win(self):
        total_pairs = len(self.cards) // 2
        if self.matches_found == total_pairs:
            end_time = time.time()
            duration = round(end_time - self.start_time, 2)
            
            self.info_text.value = "Vitória!"
            self.grid.visible = False
            
            # Salvar no Banco
            if self.auth_service:
                # self.auth_service.save_game_result(...) # Implementar se já tiver a tabela
                pass
            
            self.controls[0].content.controls.append(
                ft.Column([
                    ft.Icon(ft.Icons.EMOJI_EVENTS, size=80, color=ft.Colors.AMBER),
                    ft.Text(f"Tempo: {duration}s", size=20, weight=ft.FontWeight.BOLD),
                    ft.Text(f"Erros: {self.mistakes}", size=16, color=TEXT_MUTED),
                    ft.Container(height=20),
                    ft.ElevatedButton("Jogar Novamente", on_click=lambda e: self.reset_game()),
                    ft.OutlinedButton("Voltar ao Início", on_click=lambda e: self.page.go("/dashboard/patient"))
                ], horizontal_alignment=ft.CrossAxisAlignment.CENTER)
            )
            self.update()

    def reset_game(self):
        # Remove a tela de vitória e reinicia
        self.controls[0].content.controls.pop() 
        self.grid.visible = True
        self.matches_found = 0
        self.mistakes = 0
        self.selected_cards.clear()
        self.setup_board(4)
        self.update()