int main()
{
    int a[3] = {1, 2, 3};
    putarray(3, a);
    int b[4][2] = {4, 5, 6, 7, 8};
    int c[2][5][3] = {9, 10, 11, {12}, {13}};
    putarray(14, c);
    putarray(8, b);
    return 0;
}