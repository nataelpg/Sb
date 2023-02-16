_start:

    ; subq $16, %rsp            # declara espaço para duas variaveis locais longint  
    call iniciaAlocador

    movq $100, %rbx           # empilha num_bytes
    pushq %rbx  
    call best_fit
    addq $8, %rsp
    movq %rax, END_A       # guarda o endereco do primeiro bloco alocado

    movq $200, %rbx         # passa 200 como parametro de tamanho do bloco
    pushq %rbx
    call best_fit
    addq $8, %rsp
    movq %rax, END_B    # guarda o endereco do segundo bloco alocado

    movq $50, %rbx         # passa 50 como parametro de tamanho do bloco
    pushq %rbx
    call best_fit
    addq $8, %rsp
    movq %rax, END_C    # guarda o endereco do segundo bloco alocado

    movq END_A, %rbx
    pushq %rbx
    call liberaMem
    addq $8, %rsp

    movq END_C, %rbx
    pushq %rbx
    call liberaMem
    addq $8, %rsp
    
    movq $50, %rbx         # passa 50 como parametro de tamanho do bloco
    pushq %rbx
    call best_fit
    addq $8, %rsp
    movq %rax, END_C    # guarda o endereco do segundo bloco alocado

    call finalizaAlocador
    movq $60, %rax
    movq $0, %rdi
    syscall

    # print (longint) nome da variavel
    # info registers 