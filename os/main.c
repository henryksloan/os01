#define VGA_BUFFER ((volatile char *) 0xb8000)

int main() {
    VGA_BUFFER[2 + 0] = 'W';
    VGA_BUFFER[2 + 1] = 0x01;
    return 0;
}
