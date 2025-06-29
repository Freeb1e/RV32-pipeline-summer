#include <stdio.h>
#define true 1
#define false 0
#define bool int
int NUM = 0;
int board[8][8] = {
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 6, 1, 2, 3, 0, 0},
    {0, 0, 0, 4, 0, 3, 0, 0},
    {0, 0, 5, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 1, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0}}; // 0=空白 1=兵 2=马 3=象 4=车 5=王 6=后
typedef struct
{
    int x;
    int y;
    int type;
    bool valid;
} chess_pieces;
chess_pieces pieces[12];

// short board_solve[11][8][8];//用来存放已经解出的步骤
// short ex_board[8][8];//用来存放回溯中的上一步的解

int step[12] = {-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1};
int step_num = 0;

typedef struct
{
    int x1;
    int y1;
    int x2;
    int y2;
    int type1;
    int type2;
} chess_step;

chess_step steps[12];

void check_attack();

// ...existing code...

int abs(int value)
{
    return value < 0 ? -value : value;
}

// ...existing code...

void attack(int i, int c)
{
    int ex_x, ex_y;
    ex_x = pieces[i].x;
    ex_y = pieces[i].y;
    pieces[c].valid = false;

    steps[step_num].x1 = pieces[i].x;
    steps[step_num].y1 = pieces[i].y;
    steps[step_num].x2 = pieces[c].x;
    steps[step_num].y2 = pieces[c].y;
    steps[step_num].type1 = pieces[i].type;
    steps[step_num].type2 = pieces[c].type;

    pieces[i].x = pieces[c].x;
    pieces[i].y = pieces[c].y;
    step[step_num] = c;
    step_num++;
    // for (int p = 0; p < NUM; p++)
    // {
    //      cout<<step[p]<<" ";
    //  }
    // cout<<endl;

    check_attack();
    pieces[c].valid = true;
    pieces[c].x = pieces[i].x;
    pieces[c].y = pieces[i].y;
    pieces[i].x = ex_x;
    pieces[i].y = ex_y;
    step_num--;
    step[step_num] = -1;
    //   for (int p = 0; p < NUM; p++)
    //  {
    //      cout<<step[p]<<" ";
    //  }
    // cout<<endl;
}

void check_attack()
{
    if (step_num == NUM - 1)
    {
        printf("Solved!\n");
        for (int i = 0; i <= NUM - 2; i++)
        {
            printf("%d %d(%d)--->%d %d(%d)\n", steps[i].x1 + 1, steps[i].y1 + 1, steps[i].type1, steps[i].x2 + 1, steps[i].y2 + 1, steps[i].type2);
        }
        for (int p = 0; p < NUM - 1; p++)
        {
            printf("%d ", step[p] + 1);
        }
        printf("\n");
        return;
    }
    for (int m = 0; m <= NUM - 1; m++)
    {
        if (pieces[m].valid)
        {
            bool mfind[8] = {true, true, true, true, true, true, true, true};
            int d = 1;
            switch (pieces[m].type)
            {
            case 1: // 兵
                for (int s = 0; s <= NUM - 1; s++)
                {
                    if ((pieces[s].valid) && (pieces[s].y == pieces[m].y - 1) && (pieces[s].x == pieces[m].x - 1))
                    {
                        attack(m, s);
                    }
                    else if ((pieces[s].valid) && (pieces[s].y == pieces[m].y - 1) && (pieces[s].x == pieces[m].x + 1))
                    {
                        attack(m, s);
                    }
                }
                break;
            case 2: // 马
                for (int s = 0; s <= NUM - 1; s++)
                {
                    if ((pieces[s].valid) && (abs(pieces[s].y - pieces[m].y) == 2) && (abs(pieces[s].x - pieces[m].x) == 1))
                    {
                        attack(m, s);
                    }
                    else if ((pieces[s].valid) && (abs(pieces[s].y - pieces[m].y) == 1) && (abs(pieces[s].x - pieces[m].x) == 2))
                    {
                        attack(m, s);
                    }
                }
                break;

            case 3: // 象
                d = 1;
                while ((mfind[1] || mfind[2] || mfind[3] || mfind[0]) && (d <= 7))
                {
                    for (int s = 0; s <= NUM - 1; s++)
                    {
                        if (pieces[m].x + d > 7 || pieces[m].y + d > 7)
                            mfind[0] = false;
                        if (pieces[m].x + d > 7 || pieces[m].y - d < 0)
                            mfind[1] = false;
                        if (pieces[m].x - d < 0 || pieces[m].y + d > 7)
                            mfind[2] = false;
                        if (pieces[m].x - d < 0 || pieces[m].y - d < 0)
                            mfind[3] = false;
                        if ((pieces[s].valid) && (pieces[s].x == pieces[m].x + d) && (pieces[s].y == pieces[m].y + d) && mfind[0])
                        {
                            attack(m, s);
                            mfind[0] = false;
                        }
                        else if ((pieces[s].valid) && (pieces[s].x == pieces[m].x + d) && (pieces[s].y == pieces[m].y - d) && mfind[1])
                        {
                            attack(m, s);
                            mfind[1] = false;
                        }
                        else if ((pieces[s].valid) && (pieces[s].x == pieces[m].x - d) && (pieces[s].y == pieces[m].y + d) && mfind[2])
                        {
                            attack(m, s);
                            mfind[2] = false;
                        }
                        else if ((pieces[s].valid) && (pieces[s].x == pieces[m].x - d) && (pieces[s].y == pieces[m].y - d) && mfind[3])
                        {
                            attack(m, s);
                            mfind[3] = false;
                        }
                    }
                    d++;
                }
                break;
            case 4: // 车
                d = 1;
                while ((mfind[1] || mfind[2] || mfind[3] || mfind[0]) && (d <= 7))
                {
                    for (int s = 0; s <= NUM - 1; s++)
                    {
                        if (pieces[m].x + d > 7)
                            mfind[0] = false;
                        if (pieces[m].x - d < 0)
                            mfind[1] = false;
                        if (pieces[m].y + d > 7)
                            mfind[2] = false;
                        if (pieces[m].y - d < 0)
                            mfind[3] = false;
                        if ((pieces[s].valid) && (pieces[s].x == pieces[m].x + d) && (pieces[s].y == pieces[m].y) && mfind[0])
                        {
                            attack(m, s);
                            mfind[0] = false;
                        }
                        else if ((pieces[s].valid) && (pieces[s].x == pieces[m].x - d) && (pieces[s].y == pieces[m].y) && mfind[1])
                        {
                            attack(m, s);
                            mfind[1] = false;
                        }
                        else if ((pieces[s].valid) && (pieces[s].x == pieces[m].x) && (pieces[s].y == pieces[m].y + d) && mfind[2])
                        {
                            attack(m, s);
                            mfind[2] = false;
                        }
                        else if ((pieces[s].valid) && (pieces[s].x == pieces[m].x) && (pieces[s].y == pieces[m].y - d) && mfind[3])
                        {
                            attack(m, s);
                            mfind[3] = false;
                        }
                    }
                    d++;
                }
                break;
            case 5: // 王
                for (int s = 0; s <= NUM - 1; s++)
                {
                    if ((pieces[s].valid) && (abs(pieces[s].x - pieces[m].x) <= 1) && (abs(pieces[s].y - pieces[m].y) <= 1) && (s != m))
                        attack(m, s);
                }
                break;
            case 6: // 后
                d = 1;
                while ((d <= 7) && (mfind[1] || mfind[2] || mfind[3] || mfind[4] || mfind[5] || mfind[6] || mfind[7] || mfind[0]))
                {
                    for (int s = 0; s <= NUM - 1; s++)
                    {
                        if (pieces[m].x + d > 7 || pieces[m].y + d > 7)
                            mfind[0] = false;
                        if (pieces[m].x + d > 7 || pieces[m].y - d < 0)
                            mfind[1] = false;
                        if (pieces[m].x - d < 0 || pieces[m].y + d > 7)
                            mfind[2] = false;
                        if (pieces[m].x - d < 0 || pieces[m].y - d < 0)
                            mfind[3] = false;
                        if (pieces[m].x + d > 7)
                            mfind[4] = false;
                        if (pieces[m].x - d < 0)
                            mfind[5] = false;
                        if (pieces[m].y + d > 7)
                            mfind[6] = false;
                        if (pieces[m].y - d < 0)
                            mfind[7] = false;
                        if ((pieces[s].valid) && (pieces[s].x == pieces[m].x + d) && (pieces[s].y == pieces[m].y + d) && mfind[0])
                        {
                            attack(m, s);
                            mfind[0] = false;
                        }
                        else if ((pieces[s].valid) && (pieces[s].x == pieces[m].x + d) && (pieces[s].y == pieces[m].y - d) && mfind[1])
                        {
                            attack(m, s);
                            mfind[1] = false;
                        }
                        else if ((pieces[s].valid) && (pieces[s].x == pieces[m].x - d) && (pieces[s].y == pieces[m].y + d) && mfind[2])
                        {
                            attack(m, s);
                            mfind[2] = false;
                        }
                        else if ((pieces[s].valid) && (pieces[s].x == pieces[m].x - d) && (pieces[s].y == pieces[m].y - d) && mfind[3])
                        {
                            attack(m, s);
                            mfind[3] = false;
                        }
                        else if ((pieces[s].valid) && (pieces[s].x == pieces[m].x + d) && (pieces[s].y == pieces[m].y) && mfind[4])
                        {
                            attack(m, s);
                            mfind[4] = false;
                        }
                        else if ((pieces[s].valid) && (pieces[s].x == pieces[m].x - d) && (pieces[s].y == pieces[m].y) && mfind[5])
                        {
                            attack(m, s);
                            mfind[5] = false;
                        }
                        else if ((pieces[s].valid) && (pieces[s].x == pieces[m].x) && (pieces[s].y == pieces[m].y + d) && mfind[6])
                        {
                            attack(m, s);
                            mfind[6] = false;
                        }
                        else if ((pieces[s].valid) && (pieces[s].x == pieces[m].x) && (pieces[s].y == pieces[m].y - d) && mfind[7])
                        {
                            attack(m, s);
                            mfind[7] = false;
                        }
                    }
                    d++;
                }
                break;
            }
        }
    }
}

int main()
{
    NUM = 0;
    for (int i = 0; i <= 7; i++)
        for (int j = 0; j <= 7; j++)
        {
            if (board[i][j] != 0)
            {
                pieces[NUM].x = j;
                pieces[NUM].y = i;
                pieces[NUM].type = board[i][j];
                pieces[NUM].valid = true;
                NUM++;
            }
        }
    for (int i = 0; i <= NUM - 1; i++)
    {
        printf("%d %d %d\n", pieces[i].x + 1, pieces[i].y + 1, pieces[i].type);
    }
    printf("NUM=%d\n", NUM);
    check_attack();
    printf("No solution!\n");
    return 0;
}