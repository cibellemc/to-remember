import flet as ft
from common.colors import BACKGROUND_LIGHT, PRIMARY, TEXT_LIGHT, TEXT_MUTED

class SelectRoleView(ft.View):
    def __init__(self, page: ft.Page):
        super().__init__(
            route="/select-role",
            bgcolor=BACKGROUND_LIGHT, 
            padding=ft.padding.all(20)
        )
        self.page = page
        self.selected_role = None 

        self.continue_button = ft.Container(
            content=ft.ElevatedButton(
                text="Continuar",
                on_click=self.go_to_login,
                style=ft.ButtonStyle(
                    padding=ft.padding.symmetric(vertical=24, horizontal=32),
                    text_style=ft.TextStyle(
                        size=18, 
                        weight=ft.FontWeight.BOLD
                    ),
                    shape=ft.RoundedRectangleBorder(radius=10) 
                ),
                expand=True,
            ),
            padding=ft.padding.only(bottom=40, left=40, right=40), 
            alignment=ft.alignment.center,
            visible=False 
        )
        
        # --- Cards de Alto Contraste ---
        self.patient_card = self.create_role_card(
            role_name="patient",
            title="Paciente",
            subtitle="A pessoa que vai treinar a memória",
            icon_control=ft.Icon(
                ft.Icons.ELDERLY, 
                size=60, 
                color=PRIMARY 
            )
        )
        
        self.caregiver_card = self.create_role_card(
            role_name="caregiver",
            title="Cuidador",
            subtitle="Alguém que ajuda outra pessoa",
            icon_control=ft.Icon(
                ft.Icons.HEALTH_AND_SAFETY_OUTLINED, 
                size=60, 
                color=PRIMARY
            )
        )

        # --- Layout Principal (sem mudanças) ---
        header_block = ft.Column(
            [
                ft.Text(
                    value="Selecione o seu perfil",
                    size=24,
                    weight=ft.FontWeight.BOLD,
                    text_align=ft.TextAlign.CENTER,
                    color=TEXT_LIGHT, 
                ),
                ft.Text(
                    value="Quem vai usar este aplicativo?",
                    size=16,
                    text_align=ft.TextAlign.CENTER,
                    color=TEXT_MUTED, 
                ),
            ],
            horizontal_alignment=ft.CrossAxisAlignment.CENTER,
            spacing=5
        )

        cards_row = ft.Row(
            [
                self.patient_card,
                self.caregiver_card,
            ],
            alignment=ft.MainAxisAlignment.CENTER,
            spacing=20,
        )

        main_content = ft.Container(
            content=ft.Column(
                [
                    header_block,
                    cards_row,
                ],
                horizontal_alignment=ft.CrossAxisAlignment.CENTER,
                alignment=ft.MainAxisAlignment.CENTER,
                spacing=30, 
            ),
            alignment=ft.alignment.center,
            expand=True,
        )

        self.controls = [
            ft.Column(
                [
                    main_content,
                    self.continue_button 
                ],
                expand=True,
                horizontal_alignment=ft.CrossAxisAlignment.CENTER,
                alignment=ft.MainAxisAlignment.CENTER,
            )
        ]

    def create_role_card(self, role_name: str, title: str, subtitle: str, icon_control: ft.Icon):
        
        # Cria os controles de texto
        title_text = ft.Text(
            title, 
            size=20, 
            weight=ft.FontWeight.BOLD, 
            color=TEXT_LIGHT 
        )
        
        subtitle_text = ft.Text(
            subtitle, 
            size=14, 
            color=TEXT_MUTED, 
            text_align=ft.TextAlign.CENTER
        )
        
        # Cria o card (Container)
        card = ft.Container(
            content=ft.Column(
                [
                    icon_control,
                    title_text,
                    subtitle_text
                ],
                horizontal_alignment=ft.CrossAxisAlignment.CENTER,
                alignment=ft.MainAxisAlignment.CENTER,
                spacing=10,
            ),
            width=160,  
            height=200, 
            border_radius=12,
            
            bgcolor=ft.Colors.WHITE, 
            border=ft.border.all(2, ft.Colors.GREY_300), 
            on_click=lambda e: self.select_role(role_name),
            data=role_name,
            padding=ft.padding.all(15),
        )
        
        # --- MÁGICA AQUI ---
        # Armazena referências aos controles dentro do próprio card
        # para que 'select_role' possa acessá-los
        card.icon_control = icon_control
        card.title_text = title_text
        card.subtitle_text = subtitle_text
        
        return card

    # 2. FUNÇÃO ATUALIZADA: select_role
    def select_role(self, role: str):
        """
        Atualiza os cards para refletir a seleção com 
        alto contraste (fundo e cores de texto).
        """
        self.selected_role = role
        
        # --- ESTADO DE RESET (Não Selecionado) ---
        # Define o estado de "não selecionado" para AMBOS os cards
        
        # Card Paciente (Reset)
        self.patient_card.bgcolor = ft.Colors.WHITE
        self.patient_card.border = ft.border.all(2, ft.Colors.GREY_300)
        self.patient_card.icon_control.color = PRIMARY
        self.patient_card.title_text.color = TEXT_LIGHT
        self.patient_card.subtitle_text.color = TEXT_MUTED
        
        # Card Cuidador (Reset)
        self.caregiver_card.bgcolor = ft.Colors.WHITE
        self.caregiver_card.border = ft.border.all(2, ft.Colors.GREY_300)
        self.caregiver_card.icon_control.color = PRIMARY
        self.caregiver_card.title_text.color = TEXT_LIGHT
        self.caregiver_card.subtitle_text.color = TEXT_MUTED

        # --- ESTADO SELECIONADO ---
        # Aplica o estado de "selecionado" (alto contraste)
        # apenas no card que foi clicado.
        
        selected_card = None
        if role == "patient":
            selected_card = self.patient_card
        else:
            selected_card = self.caregiver_card
            
        # Altera o fundo para a cor primária
        selected_card.bgcolor = PRIMARY 
        # Altera a borda (a sua borda branca é uma boa ideia)
        selected_card.border = ft.border.all(4, ft.Colors.WHITE)
        
        # --- MUDANÇA DE ACESSIBILIDADE ---
        # Altera TODAS as cores internas para BRANCO
        selected_card.icon_control.color = ft.Colors.WHITE
        selected_card.title_text.color = ft.Colors.WHITE
        selected_card.subtitle_text.color = ft.Colors.WHITE
            
        # Exibe o botão de continuar
        self.continue_button.visible = True
        self.update() # Atualiza a UI para mostrar as mudanças

    # 3. Lógica de navegação (sem mudanças)
    def go_to_login(self, e):
        if self.selected_role:
            self.page.go(f"/login/{self.selected_role}")