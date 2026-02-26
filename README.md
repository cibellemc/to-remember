# To Remember

Este é um aplicativo em Flutter focado em auxiliar pacientes lidando com declínio cognitivo e seus cuidadores, trazendo recursos de jogos, interação e acompanhamento diário.

## O que foi desenvolvido até agora (Módulo de Autenticação)

O fluxo de **Login e Cadastro** foi completamente construído de forma fluida (*Wizard* / passo-a-passo), com foco extremo em **acessibilidade** e em gerar a melhor experiência para usuários idosos ou com dificuldades de leitura.

### Funcionalidades do Fluxo de Login:
- **Navegação Progressiva:** O usuário é guiado progressivamente tela a tela ("Como você quer usar o app?" -> "É sua primeira vez aqui?" -> "Qual seu perfil?" -> "Informações básicas").
- **Separação Inteligente de Perfis:** Fluxos se adaptam automaticamente baseados na escolha inicial de "Paciente" ou "Cuidador" (incluindo Familiar vs Médico/Enfermeiro).
- **UX/UI Focado na Terceira Idade (Acessibilidade Visual):**
  - Textos, botões, descrições e ícones utilizam fontes grandes e generosas margens de clique.
  - Barra de progresso puramente visual (minimalista), evitando letreiros minúsculos esmagados no topo da tela.
  - Redução de carga cognitiva: campos irrelevantes para o core do registro (como Data de Nascimento) foram removidos para evitar atritos.
- **Integração de Estado com Provider:** Todo o cérebro das páginas vive dentro do `LoginViewModel`, cuidando de validações de senhas, habilitando os botões na hora certa e escondendo/revelando senhas.
- **Validação Específica para Profissionais:** Cuidadores do tipo "Médico" precisam preencher seus dados profissionais (CRM/Especialidade) numa etapa própria do fluxo.

## Como rodar o projeto localmente

Siga os passos abaixo para compilar e testar o aplicativo no seu computador:

### Pré-requisitos
- [Flutter SDK](https://docs.flutter.dev/get-started/install) instalado.
- Um emulador (Android/iOS) rodando ou um dispositivo físico plugado por USB/Wi-Fi.

### Passos para Execução:

1. Faça o clone do repositório ou navegue até a pasta do projeto no seu terminal:
   ```bash
   cd to_remember
   ```

2. Restaure as dependências do Flutter (packages):
   ```bash
   flutter pub get
   ```

3. Gire a chave e execute o aplicativo!
   ```bash
   flutter run
   ```

> **Dica**: Caso esteja usando o VS Code ou o Android Studio, você pode rodar apertando a tecla `F5` de dentro próprio arquivo `main.dart`.