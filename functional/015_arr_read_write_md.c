int main()
{
    int a[15];
    int b[5][3] = {};
    int c[5][3] = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15};
    int d[5][3] = {{1, 2, 3}, {4, 5, 6}, {7, 8, 9}, {10, 11, 12}, {13, 14, 15}};
    int e[5][3] = {1, 2, 3, {4}, {7}, 10, 11, 12, {13}};

    int i = e[1][1]; // i = 0
    int j = c[0][1]; // j = 2
    int k = d[2][0]; // k = 7
    
    b[i][1] = 1;
    b[1][1] = k;
    b[1][j] = 3;
    b[2][0] = 4;
    b[2][2] = 5;
    int m = b[1][1]; // m = 7

    return m;
}