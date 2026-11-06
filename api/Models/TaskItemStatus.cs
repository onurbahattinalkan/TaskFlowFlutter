namespace TaskFlowApi.Models;

// Görev durumu; veritabanında sayı olarak (0, 1, 2) saklanır
public enum TaskItemStatus
{
    Todo = 0,        // Yapılacak
    InProgress = 1,  // Devam Ediyor
    Done = 2         // Tamamlandı
}